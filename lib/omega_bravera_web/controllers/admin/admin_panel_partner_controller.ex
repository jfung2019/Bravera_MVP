defmodule OmegaBraveraWeb.AdminPanelPartnerController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Groups
  plug :assign_available_options when action in [:edit, :new]

  def index(conn, params) do
    results = Turbo.Ecto.turbo(Groups.Partner, params, entry_name: "partners")
    render(conn, partners: results.partners, paginate: results.paginate)
  end

  def show(conn, %{"id" => partner_id}) do
    partner = Groups.get_partner!(partner_id)

    render(conn, "show.html",
      partner: partner,
      offers: OmegaBravera.Offers.list_offers_all_offers()
    )
  end

  def edit(conn, %{"id" => partner_id}) do
    partner = Groups.get_partner!(partner_id)
    if partner.location == nil, do: %{partner | location: %Groups.PartnerLocation{}}
    render(conn, partner: partner, changeset: Groups.change_partner(partner))
  end

  def new(conn, _params),
    do: render(conn, "new.html", changeset: Groups.change_partner(%Groups.Partner{}))

  def create(conn, %{"partner" => partner_params}) do
    case Groups.create_partner(partner_params) do
      {:ok, partner} ->
        conn
        |> put_flash(:info, "Partner created successfully")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> assign_available_options(nil)
        |> put_flash(:error, "Partner wasn't created")
        |> render("new.html", changeset: changeset)
    end
  end

  def update(conn, %{"partner" => partner_params, "id" => id}) do
    partner = Groups.get_partner!(id)

    case Groups.update_partner(partner, partner_params) do
      {:ok, partner} ->
        conn
        |> put_flash(:info, "Partner updated successfully")
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> assign_available_options(nil)
        |> put_flash(:error, "Partner was not updated")
        |> render("edit.html", changeset: changeset, partner: partner)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_approval_statuses, Groups.Partner.available_approval_status())
  end
end
