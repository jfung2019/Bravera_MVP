defmodule OmegaBraveraWeb.NGOChalController do
  use OmegaBraveraWeb, :controller
  use Timex
  alias Decimal
  alias Numbers

  alias OmegaBravera.{Accounts, Challenges, Fundraisers, Money}
  alias OmegaBravera.Challenges.NGOChal
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Slugify

  def index(conn, _params) do
    ngo_chals = Challenges.list_ngo_chals()
    render(conn, "index.html", ngo_chals: ngo_chals)
  end

  def new(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user !== nil ->
        # TODO slugify this ngo_id reqest
        %{params: %{"ngo_slug" => ngo_slug}} = conn

        ngo = Fundraisers.get_ngo_by_slug(ngo_slug)

        changeset = Challenges.change_ngo_chal(%NGOChal{default_currency: ngo.currency})
        render(conn, "new.html", changeset: changeset, ngo: ngo)

      true ->
        redirect(conn, to: "/login")
    end
  end

  def create(conn, %{"ngo_slug" => ngo_id, "ngo_chal" => chal_params}) do
    current_user = Guardian.Plug.current_resource(conn)
    sluggified_username = Slugify.gen_random_slug(current_user.firstname)

    # Oddly, ngo_slug = ngo_id here...
    ngo = Fundraisers.get_ngo!(ngo_id)

    changeset_params =
      Map.merge(chal_params, %{
        "user_id" => current_user.id,
        "ngo_id" => ngo.id,
        "slug" => sluggified_username
      })

    case Challenges.create_ngo_chal(%NGOChal{}, changeset_params) do
      {:ok, challenge} ->
        challenge_path = ngo_ngo_chal_path(conn, :show, ngo.slug, sluggified_username)
        Challenges.Notifier.send_challenge_signup_email(challenge, challenge_path)

        conn
        |> put_flash(:info, "Success! You have registered for the challenge!")
        |> redirect(to: challenge_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, ngo: ngo)
    end
  end

  def show(conn, %{"slug" => slug}) do
    challenge = Challenges.get_ngo_chal_by_slug(slug, user: [:strava], ngo: [])
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
    challenge = Challenges.get_ngo_chal_by_slug(slug, [:user, :ngo])

    Challenges.Notifier.send_buddies_invite_email(challenge, Map.values(buddies))

    redirect(conn, to: ngo_ngo_chal_path(conn, :show, ngo_slug, slug))
  end

  defp milestone_stats(ngo_chal) do
    import Enum, only: [map: 2, into: 2]
    alias Decimal, as: D

    ngo_chal
    |> Money.milestones_donations()
    # strigify values
    |> map(fn {k, v} ->
      {to_string(k), into(map(v, fn {kk, vv} -> {kk, D.to_string(vv)} end), %{})}
    end)
    |> into(%{})
  end
end
