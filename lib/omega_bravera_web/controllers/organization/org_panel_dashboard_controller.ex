defmodule OmegaBraveraWeb.OrgPanelDashboardController do
  use OmegaBraveraWeb, :controller

  def index(%{assigns: %{organization_id: org_id}} = conn, _params) do
    render(conn, "index.html", no_groups: !OmegaBravera.Groups.has_groups?(org_id))
  end

  def guides(conn, _param) do
    render(conn, "guides.html")
  end
end
