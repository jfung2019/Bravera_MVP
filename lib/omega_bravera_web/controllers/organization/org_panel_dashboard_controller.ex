defmodule OmegaBraveraWeb.OrgPanelDashboardController do
  use OmegaBraveraWeb, :controller

  def index(conn, _param) do
    render(conn, "index.html")
  end

  def guides(conn, _param) do
    render(conn, "guides.html")
  end
end
