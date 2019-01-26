defmodule OmegaBraveraWeb.NGOChalController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  alias OmegaBravera.{
    Accounts,
    Challenges,
    Challenges.NGOChal,
    Challenges.Team,
    Fundraisers,
    Money,
    Fundraisers.NGO,
    Money.Donation,
    Slugify
  }

  plug(:assign_available_options when action in [:new, :edit, :create])

  def index(conn, _params) do
    ngo_chals = Challenges.list_ngo_chals()
    render(conn, "index.html", ngo_chals: ngo_chals)
  end

  def new(conn, %{"ngo_slug" => ngo_slug}) do
    ngo = Fundraisers.get_ngo_with_stats(ngo_slug)
    current_user = Guardian.Plug.current_resource(conn)
    changeset = Challenges.change_ngo_chal(%NGOChal{})

    render(conn, "new.html", changeset: changeset, ngo: ngo, current_user: current_user)
  end

  def create(conn, %{"ngo_slug" => ngo_slug, "ngo_chal" => chal_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    ngo = Fundraisers.get_ngo_by_slug(ngo_slug)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    chal_params = put_in(chal_params, ["team", "user_id"], current_user.id)

    extra_params = %{
      "user_id" => current_user.id,
      "ngo_slug" => ngo_slug,
      "ngo_id" => ngo.id,
      "slug" => sluggified_username,
      "default_currency" => ngo.currency,
      "status" => gen_challenge_status(ngo)
    }

    changeset_params = Map.merge(chal_params, extra_params)

    case create_challenge(ngo, changeset_params) do
      {:ok, challenge} ->
        challenge_path = ngo_ngo_chal_path(conn, :show, ngo.slug, sluggified_username)
        send_emails(challenge, challenge_path)

        conn
        |> put_flash(:info, "Success! You have registered for the challenge!")
        |> redirect(to: challenge_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("new.html",
          changeset: changeset,
          ngo: ngo,
          current_user: Guardian.Plug.current_resource(conn)
        )
    end
  end

  def show(conn, %{"ngo_slug" => ngo_slug, "slug" => slug}) do
    challenge =
      Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [], team: [])

    changeset = Money.change_donation(%Donation{currency: challenge.default_currency})

    render_attrs = get_render_attrs(conn, challenge, changeset, ngo_slug)

    render(conn, "show.html", Map.merge(render_attrs, get_stats(challenge)))
  end

  def edit(conn, %{"id" => id}) do
    ngo_chal = Challenges.get_ngo_chal!(id)
    changeset = Challenges.change_ngo_chal(ngo_chal)
    render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
  end

  # Not used but we can use it if we decide to enable editing a Challenge.
  def update(conn, %{"id" => id, "ngo_chal" => ngo_chal_params}) do
    ngo_chal = Challenges.get_ngo_chal!(id)

    case Challenges.update_ngo_chal(ngo_chal, ngo_chal_params) do
      {:ok, ngo_chal} ->
        ngo_chal = ngo_chal |> OmegaBravera.Repo.preload(:ngo)

        conn
        |> put_flash(:info, "Ngo chal updated successfully.")
        |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_chal.ngo.slug, ngo_chal.slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
    end
  end

  def invite_buddies(conn, %{
        "ngo_chal_slug" => slug,
        "ngo_slug" => ngo_slug,
        "buddies" => buddies
      }) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:user, :ngo])

    Challenges.Notifier.send_buddies_invite_email(challenge, Map.values(buddies))

    # To trigger social share modal on invites.
    challenge_path = ngo_ngo_chal_path(conn, :show, ngo_slug, slug) <> "#share"
    redirect(conn, to: challenge_path)
  end

  def invite_team_members(conn, %{
        "ngo_chal_slug" => slug,
        "ngo_slug" => ngo_slug,
        "team_members" => team_members
      }) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, [:user, :ngo, :team])

    sent_invite_tokens =
      Challenges.Notifier.send_team_members_invite_email(challenge, Map.values(team_members))

    remaining_invite_tokens = challenge.team.invite_tokens -- sent_invite_tokens
    all_sent_invite_tokens = sent_invite_tokens ++ (challenge.team.sent_invite_tokens || [])

    case Challenges.update_team(challenge.team, %{
           invite_tokens: remaining_invite_tokens,
           sent_invite_tokens: all_sent_invite_tokens
         }) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Sucessfully invited your team members!")
        |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))

      {:error, _reason} ->
        conn
        |> put_flash(:info, "Something went wrong while updating your team.")
        |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
    end
  end

  def add_team_member(conn, %{"invitation_token" => invitation_token}) do
    # TODO: either create an account for the user and join the team for him
    # or force him to go to /login first. But I will also need to store the
    # invite token somewhere so that
    # OR say in the email: someone invited you to his team:
    # 1- create your account.
    # 2- click the invitation link while you are logged in.
  end

  defp get_render_attrs(conn, %NGOChal{type: "PER_MILESTONE"} = challenge, changeset, ngo_slug) do
    %{
      challenge: challenge,
      m_targets: NGOChal.milestones_distances(challenge),
      changeset: changeset,
      stats: get_stats(challenge),
      donors: Accounts.latest_donors(challenge, 5),
      activities: Challenges.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      ngo_with_stats: Fundraisers.get_ngo_with_stats(ngo_slug)
    }
  end

  defp get_render_attrs(conn, %NGOChal{type: "PER_KM"} = challenge, changeset, ngo_slug) do
    %{
      challenge: challenge,
      changeset: changeset,
      donors: Accounts.latest_km_donors(challenge, 5),
      activities: Challenges.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn),
      total_pledges_per_km: Challenges.get_per_km_challenge_total_pledges(challenge.slug),
      ngo_with_stats: Fundraisers.get_ngo_with_stats(ngo_slug)
    }
  end

  defp gen_challenge_status(%NGO{
         open_registration: open_registration,
         utc_launch_date: utc_launch_date
       }) do
    case open_registration == false and Timex.after?(utc_launch_date, Timex.now()) do
      true ->
        "pre_registration"

      _ ->
        "active"
    end
  end

  defp create_challenge(%NGO{} = ngo, attrs) do
    case attrs["has_team"] do
      "true" ->
        Challenges.create_ngo_chal_with_team(%NGOChal{}, ngo, attrs)

      _ ->
        Challenges.create_ngo_chal(%NGOChal{}, ngo, attrs)
    end
  end

  defp send_emails(%NGOChal{status: status} = challenge, challenge_path) do
    case status do
      "pre_registration" ->
        Challenges.Notifier.send_pre_registration_challenge_sign_up_email(
          challenge,
          challenge_path
        )

      _ ->
        Challenges.Notifier.send_challenge_signup_email(challenge, challenge_path)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_challenge_types, Challenges.available_challenge_types())
  end
end
