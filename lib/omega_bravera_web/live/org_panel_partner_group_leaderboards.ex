defmodule OmegaBraveraWeb.OrgGroupLeaderboards do
  use OmegaBraveraWeb, :live_view

  def mount(params, _session, socket) do
    {:ok, assign(socket, :router_params, params)}
  end

  def render(assigns) do
    ~L"""
    <div class="container-fluid">
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
      <input type="text" name="">
      <button type="button" class="btn btn-primary" id="filter">Search</button>
      <div class="card">
         <canvas id="myChart" width="100" height="38" phx-hook="chartHook" data-json=
          ' {
            "Result": {
              "Users": [
              {
                "name": "user 1",
                "value": 50,
                "image": "https://picsum.photos/30/30?random=1",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 2",
                "value": 80,
                "image": "https://picsum.photos/30/30?random=1",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 3",
                "value": 100,
                "image": "https://picsum.photos/30/30?random=3",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 4",
                "value": 40,
                "image": "https://picsum.photos/30/30?random=4",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 5",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 6",
                "value": 70,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 7",
                "value": 99,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 8",
                "value": 88,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 9",
                "value": 200,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 10",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 11",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 12",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 13",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 14",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 15",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 16",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 17",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 18",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 19",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 20",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 21",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 22",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 23",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 24",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 25",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 26",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 27",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 28",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 29",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              },
              {
                "name": "user 30",
                "value": 150,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              }
              ]
             }
          }'
         ></canvas>

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
