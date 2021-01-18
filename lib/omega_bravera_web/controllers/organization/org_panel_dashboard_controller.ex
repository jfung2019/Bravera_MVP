defmodule OmegaBraveraWeb.OrgPanelDashboardController do
  use OmegaBraveraWeb, :controller

  def index(conn, _params) do
    no_groups =
      OmegaBravera.Groups.organization_group_count(get_session(conn, :organization_id)) < 1

    render(conn, "index.html", no_groups: no_groups)
  end

  def guides(conn, _param) do
    render(conn, "guides.html")
  end
end
