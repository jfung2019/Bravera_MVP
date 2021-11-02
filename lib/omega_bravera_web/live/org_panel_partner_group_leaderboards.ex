defmodule OmegaBraveraWeb.OrgGroupLeaderboardsLive do
  use OmegaBraveraWeb, :live_view

  def mount(params, _session, socket) do
    {:ok, assign(socket, :router_params, params)}
  end

  def render(assigns) do
    ~L"""
    <div class="container">
      <h2>Leaderboard</h2>

      <div class="col mt-2">
        <div class="row">
          Distance (in KM)
        </div>

        <div class="card">
          <%= live_render(@socket,
            OmegaBraveraWeb.Chart,
            id: :distance_leaderboard,
            session: %{"router_params" => @router_params}
          )%>
        </div>
      </div>

    </div>
    """
  end
end
