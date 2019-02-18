defmodule OmegaBraveraWeb.AdminPanelActivitiesSyncerController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.ActivitySyncer

  def index(conn, _params) do
    Task.async(ActivitySyncer, :sync, [])
    render(conn, "index.html")
  end
end
