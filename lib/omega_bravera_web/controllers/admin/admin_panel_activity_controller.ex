defmodule OmegaBraveraWeb.AdminPanelActivityController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.ActivitySyncer

  def index(conn, _params) do
    ActivitySyncer.sync()
    render(conn, "index.html")
  end
end
