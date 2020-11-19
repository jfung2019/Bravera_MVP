defmodule OmegaBraveraWeb.AdminPanelPartnerLocationController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Groups

  def new(conn, %{"admin_panel_partner_id" => partner_id}) do
    partner = Groups.get_partner!(partner_id)

    render(conn, "new.html",
      changeset: Groups.change_partner_location(%Groups.PartnerLocation{}),
      partner: partner
    )
  end

  def create(conn, %{
        "admin_panel_partner_id" => partner_id,
        "partner_location" => location_params
      }) do
    partner = Groups.get_partner!(partner_id)

    case Groups.create_partner_location(Map.put(location_params, "partner_id", partner.id)) do
      {:ok, _location} ->
        conn
        |> put_flash(:info, "Partner location created")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "")
        |> render("new.html", changeset: changeset, partner: partner)
    end
  end

  def edit(conn, %{"admin_panel_partner_id" => partner_id, "id" => id}) do
    partner = Groups.get_partner!(partner_id)
    location = Groups.get_partner_location!(id)

    render(conn, "edit.html",
      partner: partner,
      location: location,
      changeset: Groups.change_partner_location(location)
    )
  end

  def update(conn, %{
        "admin_panel_partner_id" => partner_id,
        "id" => id,
        "partner_location" => location_params
      }) do
    partner = Groups.get_partner!(partner_id)
    location = Groups.get_partner_location!(id)

    case Groups.update_partner_location(location, location_params) do
      {:ok, _location} ->
        conn
        |> put_flash(:info, "Partner location updated")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "")
        |> render("edit.html", changeset: changeset, partner: partner)
    end
  end

  def delete(conn, %{"admin_panel_partner_id" => partner_id, "id" => id}) do
    partner = Groups.get_partner!(partner_id)
    location = Groups.get_partner_location!(id)
    Groups.delete_partner_location(location)

    conn
    |> put_flash(:info, "Partner location deleted")
    |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))
  end
end
