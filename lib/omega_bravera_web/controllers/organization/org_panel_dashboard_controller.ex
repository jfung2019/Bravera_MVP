defmodule OmegaBraveraWeb.OrgPanelDashboardController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  def index(%{assigns: %{organization_id: org_id}} = conn, _params) do
    dashboard = Accounts.organization_dashboard(org_id)
    empty_live_group_offer = OmegaBravera.Groups.check_empty_live_group_offer(org_id)

    render(conn, "index.html",
      # groups is formatted using 999,999
      # so we need to check if it's a string of 0
      empty_live_group_offer: empty_live_group_offer,
      no_groups: String.replace(dashboard.groups, " ", "") == "0",
      dashboard: dashboard
    )
  end

  def guides(conn, _param) do
    render(conn, "guides.html")
  end

  def view_as(conn, _param) do
    with admin_id <- Plug.Conn.get_session(conn, :admin_logged_in),
         false <- is_nil(admin_id),
         conn <- Plug.Conn.delete_session(conn, :admin_logged_in),
         %{id: ^admin_id} = admin <- Accounts.get_admin_user!(admin_id) do
      conn
      |> OmegaBravera.Guardian.Plug.sign_in(admin)
      |> redirect(to: Routes.admin_user_page_path(conn, :index))
    else
      _ -> redirect(conn, to: Routes.org_panel_dashboard_path(conn, :index))
    end
  end
end
