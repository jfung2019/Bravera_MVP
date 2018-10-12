defmodule OmegaBraveraWeb.AdminPanelChallengesController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges
  alias OmegaBravera.Accounts
  alias OmegaBravera.Fundraisers

  plug(:assign_available_options when action in [:edit])

  def index(conn, _params) do
    challenges = Challenges.list_ngo_chals_preload()
    render(conn, "index.html", challenges: challenges)
  end

  def show(conn, %{"slug" => slug}) do
    ngo_chal = Challenges.get_ngo_chal_by_slug(slug, user: [:strava], ngo: [])
    render(conn, "show.html", ngo_chal: ngo_chal)
  end

  def edit(conn, %{"slug" => slug}) do
    ngo_chal = Challenges.get_ngo_chal_by_slug(slug, user: [:strava], ngo: [])
    users = Accounts.list_users()
    changeset = Challenges.change_ngo_chal(ngo_chal)
    render(conn, "edit.html", users: users, ngo_chal: ngo_chal, changeset: changeset)
  end

  def update(conn, %{"slug" => slug, "ngo_chal" => ngo_chal_params}) do
    ngo_chal = Challenges.get_ngo_chal_by_slug(slug, user: [:strava], ngo: [])

    case Challenges.update_ngo_chal(ngo_chal, ngo_chal_params) do
      {:ok, ngo_chal} ->
        conn
        |> put_flash(:info, "Challenge updated successfully.")
        |> redirect(to: admin_panel_challenges_path(conn, :show, ngo_chal))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign_available_options(nil)
        |> render(conn, "edit.html", ngo_chal: ngo_chal, changeset: changeset)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_currencies, Fundraisers.available_currencies())
    |> assign(:available_activities, Fundraisers.available_activities())
    |> assign(:available_distances, Fundraisers.available_distances())
    |> assign(:available_durations, Fundraisers.available_durations())
  end
end
