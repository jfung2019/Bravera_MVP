defmodule OmegaBraveraWeb.OrgPanelLeaderboardsController do
  use OmegaBraveraWeb, :controller

  def group_leaderboards(conn, %{"org_panel_partner_id" => partner_id} = params) do
    render(conn, "index.html", partner_id: partner_id, params: params)
  end
end
