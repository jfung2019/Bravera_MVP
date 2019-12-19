defmodule OmegaBraveraWeb.AdminPanelLocationsController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Locations

  def index(conn, _params) do
    render(conn, "index.html", locations: Locations.list_locations())
  end

  def new(conn, _params) do
    render(conn, "new.html", changeset: Locations.change_location(%Locations.Location{}))
  end

  def create(conn, %{"location" => location_params}) do
    case Locations.create_location(location_params) do
      {:ok, location} ->
        redirect(conn, to: admin_panel_locations_path(conn, :show, location))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html", location: Locations.get_location!(id))
  end

  def edit(conn, %{"id" => id}) do
    location = Locations.get_location!(id)
    render(conn, "edit.html", changeset: Locations.change_location(location), location: location)
  end

  def update(conn, %{"id" => id, "location" => location_params}) do
    location = Locations.get_location!(id)

    case Locations.update_location(location, location_params) do
      {:ok, location} ->
        redirect(conn, to: admin_panel_locations_path(conn, :show, location))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, location: location)
    end
  end

  def delete(conn, %{"id" => id}) do
    location = Locations.get_location!(id)
    {:ok, _location} = Locations.delete_location(location)

    conn
    |> put_flash(:info, "Location deleted successfully.")
    |> redirect(to: admin_panel_locations_path(conn, :index))
  end
end
