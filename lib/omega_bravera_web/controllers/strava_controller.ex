defmodule OmegaBraveraWeb.StravaController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Trackers
  alias OmegaBravera.Trackers.Strava

  def index(conn, _params) do
    stravas = Trackers.list_stravas()
    render(conn, "index.html", stravas: stravas)
  end

  def new(conn, _params) do
    changeset = Trackers.change_strava(%Strava{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"strava" => strava_params}) do
    case Trackers.create_strava(strava_params) do
      {:ok, strava} ->
        conn
        |> put_flash(:info, "Strava created successfully.")
        |> redirect(to: strava_path(conn, :show, strava))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    strava = Trackers.get_strava!(id)
    render(conn, "show.html", strava: strava)
  end

  def edit(conn, %{"id" => id}) do
    strava = Trackers.get_strava!(id)
    changeset = Trackers.change_strava(strava)
    render(conn, "edit.html", strava: strava, changeset: changeset)
  end

  def update(conn, %{"id" => id, "strava" => strava_params}) do
    strava = Trackers.get_strava!(id)

    case Trackers.update_strava(strava, strava_params) do
      {:ok, strava} ->
        conn
        |> put_flash(:info, "Strava updated successfully.")
        |> redirect(to: strava_path(conn, :show, strava))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", strava: strava, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    strava = Trackers.get_strava!(id)
    {:ok, _strava} = Trackers.delete_strava(strava)

    conn
    |> put_flash(:info, "Strava deleted successfully.")
    |> redirect(to: strava_path(conn, :index))
  end
end
