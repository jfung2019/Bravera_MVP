defmodule OmegaBraveraWeb.AdminPanelPartnerLocationController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Partners

  def new(conn, %{"admin_panel_partner_id" => partner_id}) do
    partner = Partners.get_partner!(partner_id)
    render(conn, "new.html", changeset: Partners.change_partner_location(%Partners.PartnerLocation{}), partner: partner)
  end

  def create(conn, %{"admin_panel_partner_id" => partner_id, "partner_location" => location_params}) do
    partner = Partners.get_partner!(partner_id)
    case Partners.create_partner_location(Map.put(location_params, "partner_id", partner.id)) do
      {:ok, _location} ->
        conn
        |> put_flash(:info, "Partner location created")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "")
        |> render(changeset: changeset, partner: partner)
    end
  end

  def edit(conn, %{"admin_panel_partner_id" => partner_id, "id" => id}) do
    partner = Partners.get_partner!(partner_id)
    location = Partners.get_partner_location!(id)
    render(conn, "edit.html", partner: partner, location: location, changeset: Partners.change_partner_location(location))
  end

  def update(conn, %{"admin_panel_partner_id" => partner_id, "id" => id, "partner_location" => location_params}) do
    partner = Partners.get_partner!(partner_id)
    location = Partners.get_partner_location!(id)
    case Partners.update_partner_location(location, location_params) do
      {:ok, _location} ->
        conn
        |> put_flash(:info, "Partner location updated")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "")
        |> render(changeset: changeset, partner: partner)
    end
  end

  def delete(conn, %{"admin_panel_partner_id" => partner_id, "id" => id}) do
    partner = Partners.get_partner!(partner_id)
    location = Partners.get_partner_location!(id)
    Partners.delete_partner_location(location)
    conn
    |> put_flash(:info, "Partner location deleted")
    |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))
  end
end