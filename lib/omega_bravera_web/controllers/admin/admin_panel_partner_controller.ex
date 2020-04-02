defmodule OmegaBraveraWeb.AdminPanelPartnerController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Partners

  def index(conn, params) do
    results = Turbo.Ecto.turbo(Partners.Partner, params, entry_name: "partners")
    render(conn, partners: results.partners, paginate: results.paginate)
  end

  def show(conn, %{"id" => partner_id}) do
    partner = Partners.get_partner!(partner_id)
    render(conn, "show.html", partner: partner)
  end

  def edit(conn, %{"id" => partner_id}) do
    partner = Partners.get_partner!(partner_id)
    if partner.location == nil, do: %{partner | location: %Partners.PartnerLocation{}}
    render(conn, partner: partner, changeset: Partners.change_partner(partner))
  end

  def new(conn, _params),
    do: render(conn, "new.html", changeset: Partners.change_partner(%Partners.Partner{}))

  def create(conn, %{"partner" => partner_params}) do
    case Partners.create_partner(partner_params) do
      {:ok, partner} ->
        conn
        |> put_flash(:info, "Partner created successfully")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Partner wasn't created")
        |> render("new.html", changeset: changeset)
    end
  end

  def update(conn, %{"partner" => partner_params, "id" => id}) do
    partner = Partners.get_partner!(id)

    case Partners.update_partner(partner, partner_params) do
      {:ok, partner} ->
        conn
        |> put_flash(:info, "Partner updated successfully")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Partner was not updated")
        |> render("edit.html", changeset: changeset, partner: partner)
    end
  end
end
