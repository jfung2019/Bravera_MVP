defmodule OmegaBraveraWeb.OrgGroupLeaderboards do
  use OmegaBraveraWeb, :live_view

  def mount(params, _session, socket) do
    {:ok, assign(socket, :router_params, params)}
  end

  def render(assigns) do
    ~L"""
    <div class="container">
    <h2>Leaderboards</h2>

    <div class="col mt-2">
      <div class="row">
        Distance (in KM)
      </div>

      <div class="card p-0 m-0">
        <%= live_render(@socket, OmegaBraveraWeb.OrgGroupLeaderboard, id: :distance_leaderboard, session: %{
          "metrics_type" => "distance-metrics", "router_params" => @router_params
        }) %>
      </div>
    </div>


    <div class="col mt-2 mt-2">
      <div class="row">
        Sync Activity (times)
      </div>

      <div class="card">
        <%# <%= live_render(@socket, OmegaBraveraWeb.OrgGroupLeaderboards, session: %{
          "metrics_type" => "social-metrics", "partner_id" => @partner_id
        }) %>
      </div>
    </div>


    <div class="col mt-2 mt-2">
      <div class="row">
        Social Activity (times)
      </div>

      <div class="card">
        <%# <%= live_render(@socket, OmegaBraveraWeb.OrgGroupLeaderboards, session: %{
          "metrics_type" => "sync-metrics", "partner_id" => @partner_id
        }) %>
      </div>
    </div>
    </div>

    """
  end
end
