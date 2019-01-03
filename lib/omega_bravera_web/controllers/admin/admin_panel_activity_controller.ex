defmodule OmegaBraveraWeb.AdminPanelActivityController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges.{Activity, NGOChal}
  alias OmegaBravera.{Challenges, Activities, Accounts}

  def index(conn, _) do
    activities = Activities.list_activities_added_by_admin()
    render(conn, "index.html", activities: activities)
  end

  def new(conn, _) do
    changeset = Activity.create_changeset(%Strava.Activity{}, %NGOChal{})
    challenges = Challenges.list_ngo_chals([:user])

    render(conn, "new_activity.html", changeset: changeset, challenges: challenges)
  end

  def import_activity_from_strava(conn, _) do

  end

  def create(conn, %{"activity" => activity_params, "challenge_id" => challenge_id}) do
    challenge = Challenges.get_ngo_chal!(challenge_id)
    activity = activity_params |> map_keys_to_atoms()
    activity = struct(Strava.Activity, activity)

    case Activities.create_activity(activity, challenge) do
      {:ok, activity} ->
        conn
        |> put_flash(:info, "Activity created successfully.")
        |> redirect(to: admin_panel_ngo_path(conn, :show, activity))
      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  defp map_keys_to_atoms(map) when is_map(map) do
    for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
  end
end
