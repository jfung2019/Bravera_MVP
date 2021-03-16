defmodule OmegaBraveraWeb.OrgPanelPartnerController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Groups

  plug :assign_available_options when action in [:edit, :new]

  def index(%{assigns: %{organization_id: org_id}} = conn, params) do
    results = Groups.paginate_groups(org_id, params)
    offer_not_attached = Groups.check_offer_not_attached(org_id)

    render(conn,
      partners: results.partners,
      paginate: results.paginate,
      offer_not_attached: offer_not_attached
    )
  end

  def show(%{assigns: %{organization_id: org_id}} = conn, %{"id" => partner_id}) do
    partner = Groups.get_partner!(partner_id)

    render(conn, "show.html",
      partner: partner,
      first_10_groups: Groups.organization_group_count(org_id) <= 10,
      offers: OmegaBravera.Offers.list_offers_by_organization(org_id)
    )
  end

  def edit(conn, %{"id" => partner_id}) do
    partner = Groups.get_partner!(partner_id)
    if partner.location == nil, do: %{partner | location: %Groups.PartnerLocation{}}
    render(conn, partner: partner, changeset: Groups.change_partner(partner))
  end

  def new(conn, _params) do
    conn
    |> assigns_for_popup()
    |> render("new.html", changeset: Groups.change_partner(%Groups.Partner{}))
  end

  def create(
        %{assigns: %{organization_id: org_id}} = conn,
        %{"partner" => partner_params} = params
      ) do
    partner_params = Map.put(partner_params, "organization_id", org_id)

    case Groups.create_org_partner(partner_params) do
      {:ok, partner} ->
        conn =
          conn
          |> put_flash(:info, "Group created successfully")

        case params do
          %{"redirect" => "edit"} ->
            redirect(conn, to: Routes.org_panel_partner_path(conn, :edit, partner))

          _ ->
            redirect(conn, to: Routes.live_path(conn, OmegaBraveraWeb.OrgPartnerImages, partner))
        end

      {:error, changeset} ->
        conn
        |> assign_available_options(nil)
        |> put_flash(:error, "Group not saved. Please check below why.")
        |> assigns_for_popup()
        |> render("new.html", changeset: changeset)
    end
  end

  def update(conn, %{"partner" => partner_params, "id" => id}) do
    partner = Groups.get_partner!(id)

    case Groups.update_org_partner(partner, partner_params) do
      {:ok, %{images: []} = partner} ->
        conn
        |> put_flash(:info, "Group updated successfully")
        |> redirect(to: Routes.live_path(conn, OmegaBraveraWeb.OrgPartnerImages, partner))

      {:ok, partner} ->
        conn
        |> put_flash(:info, "Group updated successfully")
        |> redirect(to: Routes.org_panel_partner_path(conn, :show, partner))

      {:error, changeset} ->
        conn
        |> assign_available_options(nil)
        |> put_flash(:error, "Group not saved. Please check below why.")
        |> render("edit.html", changeset: changeset, partner: partner)
    end
  end

  defp assigns_for_popup(%{assigns: %{organization_id: _org_id}} = conn) do
    conn
    |> assign(:action, Routes.org_panel_partner_path(conn, :create))
    |> assign(:edit_action, Routes.org_panel_partner_path(conn, :create, %{"redirect" => "edit"}))
    |> assign(:first_5_groups, true)
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_locations, OmegaBravera.Locations.list_locations())
  end
end
