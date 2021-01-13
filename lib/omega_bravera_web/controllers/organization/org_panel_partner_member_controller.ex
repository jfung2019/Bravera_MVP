defmodule OmegaBraveraWeb.OrgPanelPartnerMemberController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Groups

  def index(conn, %{"org_panel_partner_id" => partner_id} = params) do
    results =
      Turbo.Ecto.turbo(Groups.list_partner_members_query(partner_id), params,
        entry_name: "members"
      )

    render(conn, "index.html",
      members: results.members,
      paginate: results.paginate,
      partner_id: partner_id
    )
  end

  def delete(conn, %{"org_panel_partner_id" => partner_id, "id" => member_id}) do
    member_id
    |> Groups.get_partner_member!()
    |> Groups.delete_partner_member()

    conn
    |> put_flash(:info, "Member removed.")
    |> redirect(
      to: Routes.org_panel_partner_org_panel_partner_member_path(conn, :index, partner_id)
    )
  end
end
