defmodule OmegaBraveraWeb.OrgPanelPartnerController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Groups

  def index(%{assigns: %{organization_id: org_id}} = conn, params) do
    results = Groups.paginate_groups(org_id, params)
    render(conn, partners: results.partners, paginate: results.paginate)
  end

  def show(%{assigns: %{organization_id: org_id}} = conn, %{"id" => partner_id}) do
    partner = Groups.get_partner!(partner_id)

    render(conn, "show.html",
      partner: partner,
      first_4_group:
        Groups.organization_group_count(org_id) <= 4 and
          length(partner.offers) < 1,
      offers: OmegaBravera.Offers.list_offers_by_organization(org_id)
    )
  end

  def edit(conn, %{"id" => partner_id}) do
    partner = Groups.get_partner!(partner_id)
    if partner.location == nil, do: %{partner | location: %Groups.PartnerLocation{}}
    render(conn, partner: partner, changeset: Groups.change_partner(partner))
  end

  def new(conn, _params),
    do: render(conn, "new.html", changeset: Groups.change_partner(%Groups.Partner{}))

  def create(%{assigns: %{organization_id: org_id}} = conn, %{"partner" => partner_params}) do
    partner_params = Map.put(partner_params, "organization_id", org_id)

    case Groups.create_org_partner(partner_params) do
      {:ok, partner} ->
        conn
        |> put_flash(:info, "Partner created successfully")
        |> redirect(to: Routes.live_path(conn, OmegaBraveraWeb.OrgPartnerImages, partner))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Partner wasn't created")
        |> render("new.html", changeset: changeset)
    end
  end

  def update(conn, %{"partner" => partner_params, "id" => id}) do
    partner = Groups.get_partner!(id)

    case Groups.update_org_partner(partner, partner_params) do
      {:ok, partner} ->
        conn
        |> put_flash(:info, "Partner updated successfully")
        |> redirect(to: Routes.org_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Partner was not updated")
        |> render("edit.html", changeset: changeset, partner: partner)
    end
  end
end
