defmodule OmegaBraveraWeb.OrgPanelDashboardController do
  use OmegaBraveraWeb, :controller

  def index(conn, _param) do
    render(conn, "index.html")
  end
end