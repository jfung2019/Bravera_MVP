defmodule OmegaBraveraWeb.NGOChalController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Numbers

  alias OmegaBravera.{Accounts, Challenges, Fundraisers, Money}
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Slugify

  def index(conn, _params) do
    ngo_chals = Challenges.list_ngo_chals()
    render(conn, "index.html", ngo_chals: ngo_chals)
  end

  def new(conn, %{"ngo_slug" => ngo_slug}) do
    # TODO slugify this ngo_id request
    ngo = Fundraisers.get_ngo_by_slug(ngo_slug)

    changeset = Challenges.change_ngo_chal(%NGOChal{})
    render(conn, "new.html", changeset: changeset, ngo: ngo)
  end

  def create(conn, %{"ngo_slug" => ngo_slug, "ngo_chal" => chal_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    ngo = Fundraisers.get_ngo_by_slug(ngo_slug)

    changeset_params =
      Map.merge(chal_params, %{
        "user_id" => current_user.id,
        "ngo_slug" => ngo_slug,
        "ngo_id" => ngo.id,
        "slug" => sluggified_username,
        "default_currency" => ngo.currency
      })

    case Challenges.create_ngo_chal(%NGOChal{}, changeset_params) do
      {:ok, challenge} ->
        challenge_path = ngo_ngo_chal_path(conn, :show, ngo.slug, sluggified_username)
        Challenges.Notifier.send_challenge_signup_email(challenge, challenge_path)

        conn
        |> put_flash(:info, "Success! You have registered for the challenge!")
        |> redirect(to: challenge_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("new.html", changeset: changeset, ngo: ngo)
    end
  end

  def show(conn, %{"ngo_slug" => ngo_slug, "slug" => slug}) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [])
    changeset = Money.change_donation(%Donation{currency: challenge.default_currency})

    render_attrs = %{
      challenge: challenge,
      m_targets: NGOChal.milestones_distances(challenge),
      changeset: changeset,
      stats: milestone_stats(challenge),
      donors: Accounts.latest_donors(challenge, 5),
      activities: Challenges.latest_activities(challenge, 5),
      current_user: Guardian.Plug.current_resource(conn)
    }

    render(conn, "show.html", Map.merge(render_attrs, milestone_stats(challenge)))
  end

  def edit(conn, %{"id" => id}) do
    ngo_chal = Challenges.get_ngo_chal!(id)
    changeset = Challenges.change_ngo_chal(ngo_chal)
    render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
  end

  def update(conn, %{"id" => id, "ngo_chal" => ngo_chal_params}) do
    ngo_chal = Challenges.get_ngo_chal!(id)

    case Challenges.update_ngo_chal(ngo_chal, ngo_chal_params) do
      {:ok, ngo_chal} ->
        conn
        |> put_flash(:info, "Ngo chal updated successfully.")
        |> redirect(to: ngo_ngo_chal_path(conn, :show, ngo_chal))

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

  defp milestone_stats(ngo_chal) do
    ngo_chal
    |> Money.milestones_donations()
    |> Enum.map(fn {k, v} ->
      {to_string(k), Enum.into(Enum.map(v, fn {kk, vv} -> {kk, Decimal.to_integer(vv)} end), %{})}
    end)
    |> total_the_pledged_amount()
    |> Enum.into(%{})
  end

  defp total_the_pledged_amount(tuple_list) do
    [
      {"total",
       Enum.reduce(tuple_list, %{"pending" => 0, "charged" => 0}, fn
         {_, %{"total" => total, "charged" => charged}},
         %{"pending" => total_acc, "charged" => total_charged} ->
           %{"pending" => total + total_acc, "charged" => charged + total_charged}

         # Catch if no match
         _, acc ->
           acc
       end)}
      | tuple_list
    ]
  end
end
