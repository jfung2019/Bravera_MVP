defmodule OmegaBraveraWeb.OrgPanelDashboardController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Accounts

  def index(%{assigns: %{organization_id: org_id}} = conn, _params) do
    dashboard = Accounts.organization_dashboard(org_id)

    render(conn, "index.html",
      # groups is formatted using 999,999
      # so we need to check if it's a string of 0
      no_groups: dashboard.groups == "0",
      dashboard: dashboard
    )
  end

  def guides(conn, _param) do
    render(conn, "guides.html")
  end
end
