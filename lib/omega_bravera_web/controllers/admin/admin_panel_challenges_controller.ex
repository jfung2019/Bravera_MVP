defmodule OmegaBraveraWeb.AdminPanelChallengesController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Challenges, Fundraisers.NgoOptions}

  plug(:assign_available_options when action in [:edit])

  def index(conn, _params) do
    challenges = Challenges.list_ngo_chals()
    render(conn, "index.html", challenges: challenges)
  end

  def show(conn, %{"admin_panel_ngo_id" => ngo_slug, "id" => slug}) do
    ngo_chal = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [])
    render(conn, "show.html", ngo_chal: ngo_chal)
  end

  def edit(conn, %{"admin_panel_ngo_id" => ngo_slug, "id" => slug}) do
    ngo_chal = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [])
    users = Accounts.list_users()
    changeset = Challenges.change_ngo_chal(ngo_chal)
    render(conn, "edit.html", users: users, ngo_chal: ngo_chal, changeset: changeset)
  end

  def update(conn, %{
        "admin_panel_ngo_id" => ngo_slug,
        "id" => slug,
        "ngo_chal" => ngo_chal_params
      }) do
    ngo_chal = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [])

    case Challenges.update_ngo_chal(ngo_chal, ngo_chal_params) do
      {:ok, ngo_chal} ->
        conn
        |> put_flash(:info, "Challenge updated successfully.")
        |> redirect(
          to: admin_panel_ngo_admin_panel_challenges_path(conn, :show, ngo_chal.ngo, ngo_chal)
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        conn |> render("edit.html", ngo_chal: ngo_chal, changeset: changeset)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_currencies, NgoOptions.currency_options_human())
    |> assign(:available_activities, NgoOptions.activity_options())
    |> assign(:available_distances, NgoOptions.distance_options())
    |> assign(:available_durations, NgoOptions.duration_options())
    |> assign(:available_challenge_types, NgoOptions.challenge_type_options_human())
  end
end
