defmodule OmegaBraveraWeb.AdminPanelPartnerMemberController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Partners

  def index(conn, %{"admin_panel_partner_id" => partner_id}),
    do:
      render(conn, "index.html",
        members: Partners.list_partner_members(partner_id),
        partner_id: partner_id
      )

  def delete(conn, %{"admin_panel_partner_id" => partner_id, "id" => member_id}) do
    member_id
    |> Partners.get_partner_member!()
    |> Partners.delete_partner_member()

    conn
    |> put_flash(:info, "Member removed.")
    |> redirect(
      to: Routes.admin_panel_partner_admin_panel_partner_member_path(conn, :index, partner_id)
    )
  end
end
