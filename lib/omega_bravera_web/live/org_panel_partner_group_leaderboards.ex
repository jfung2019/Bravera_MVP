defmodule OmegaBraveraWeb.OrgGroupLeaderboardsLive do
  use OmegaBraveraWeb, :live_view
  alias Contex.{Dataset, Plot, BarChart}

  @per_page 20

  def mount(%{"id" => partner_id}, session, socket) do
    filters = %{
      "distance-chart" => %{
        "week" => %{
          "query" => {
            OmegaBravera.Accounts,
            :api_get_leaderboard_of_partner_this_week,
            [partner_id]
          },
          "field" => :total_kilometers_all_time
        },
        "month" => %{
          "query" =>
            {OmegaBravera.Accounts, :api_get_leaderboard_of_partner_this_month, [partner_id]},
          "field" => :total_kilometers_this_month
        },
        "alltime" => %{
          "query" =>
            {OmegaBravera.Accounts, :api_get_leaderboard_of_partner_all_time, [partner_id]},
          "field" => :total_kilometers
        }
      },
      "social-chart" => %{},
      "sync-chart" => %{}
    }

    socket =
      socket
      |> assign(:parent_params, Map.get(session, "router_params", %{}))
      |> assign(:partner_id, partner_id)
      |> assign(:page, 0)
      |> assign(:filters_spec, filters)

    socket =
      socket
      |> assign(
        :charts,
        generate_paginated_chart("alltime", "distance-chart", socket.assigns.filters_spec)
      )

    {:ok, socket}
  end

  def handle_event("pagination", %{"page" => page_number}, socket) do
    {page_number, _} = Integer.parse(page_number)
    {:noreply, assign(socket, :page, page_number)}
  end

  def handle_event("time_range_changed", %{"filter" => filter_type}, socket) do
    socket =
      assign(
        socket,
        :charts,
        generate_paginated_chart(filter_type, "distance-chart", socket.assigns.filters_spec)
      )

    {:noreply, socket}
  end

  defp generate_paginated_chart(type, chart_type, filters_spec) do
    %{"query" => {m, f, a}, "field" => field} = get_in(filters_spec, [chart_type, type])

    data =
      apply(m, f, a)
      |> Enum.map(fn %{username: username} = user ->
        km = Map.get(user, field, Decimal.new(0))
        {username, decimal_to_integer(km)}
      end)

    data
    |> Enum.chunk_every(@per_page)
    |> Enum.map(&generate_chart/1)
  end

  defp generate_chart(data) do
    barchart =
      data
      |> Dataset.new()
      |> BarChart.new()

    Plot.new(500, 400, barchart)
    |> Plot.to_svg()
  end

  defp decimal_to_integer(%Decimal{} = d) do
    d
    |> Decimal.to_string()
    |> Integer.parse()
    |> elem(0)
  end

  defp decimal_to_integer(_), do: 0

  def render(assigns) do
    ~L"""
    <div class="container-fluid">
     <!-- section 2: Distance-->
      <div class="wrapper">
          <div class="row mb-4 mt-2">
          <div class="col-lg-2 col-md-6 col-sm-12 p-12">
            <img class="img-responsive" src="/images/icons/distance.png" alt="Distance Icon" style="max-width:200px;">
          </div>
          <div class="col-lg-4 col-md-6 col-sm-6">
            <div class="" style="max-width: 100%;">
              <div class="p-2 admin-btn-bg-container">
                <%= live_component(@socket, OmegaBraveraWeb.TimeRangeFilters) %>
              </div>
            </div>
          </div>
          <div class="col-lg-6 col-md-12 col-sm-6 py-1">
            <form class="form-inline search-bar-container p-1 my-1 my-lg-1 bg-white" style="">
              <input class="form-control mr-2 search-bar" type="search" placeholder="Search by Alias" aria-label="Search">
              <button class="btn btn-primary my-1 my-sm-0" type="submit">Search</button>
            </form>
          </div>
        </div>
        <div class="card">
          <canvas id="myChartDistance" width="100" height="38" phx-hook="chartHook" data-json=
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
                  "value": 50,
                  "image": "https://picsum.photos/30/30?random=5",
                  "backgroundColor": "#ffb9b2"
                }
                ]
              }
            }'
          ></canvas>
          <div class="ml-4 mt-4">
            <nav aria-label="Page navigation example">
              <ul class="pagination">
                <li class="page-item"><a class="page-link" href="#">First</a></li>
                <li class="page-item">
                  <a class="page-link" href="#" aria-label="Previous">
                    <span aria-hidden="true">&laquo;</span>
                    <span class="sr-only">Previous</span>
                  </a>
                </li>
                <li class="page-item"><a class="page-link" href="#">1</a></li>
                <li class="page-item"><a class="page-link" href="#">2</a></li>
                <li class="page-item"><a class="page-link" href="#">3</a></li>
                <li class="page-item">
                  <a class="page-link" href="#" aria-label="Next">
                    <span aria-hidden="true">&raquo;</span>
                    <span class="sr-only">Next</span>
                  </a>
                </li>
                <li class="page-item"><a class="page-link" href="#">Last</a></li>
              </ul>
            </nav>
          </div>
          <!--
          <%= Enum.at(@charts, @page, "NULL!") %>
          <ul class="pagination">
            <%= for page_number <- 0..(length(@charts) - 1) do %>
            <li class="page-item">
              <a class="page-link" phx-click="pagination" phx-value-page="<%=page_number%>" href="#">
                <%=page_number + 1%>
              </a>
            </li>
            <% end%>
          </ul>
          -->
        </div>
      </div>

      <!-- section 2: Sync Activity-->
      <div class="wrapper mt-5">
      <div class="row mb-4 mt-2">
          <div class="col-lg-2 col-md-6 col-sm-12 p-12">
            <img class="img-responsive" src="/images/icons/sync_activity.png" alt="Distance Icon" style="max-width:200px;">
          </div>
          <div class="col-lg-4 col-md-6 col-sm-6">
            <div class="" style="max-width: 100%;">
              <div class="p-2 admin-btn-bg-container">
                <%= live_component(@socket, OmegaBraveraWeb.TimeRangeFilters) %>
              </div>
            </div>
          </div>
          <div class="col-lg-6 col-md-12 col-sm-6 py-1">
            <form class="form-inline search-bar-container p-1 my-1 my-lg-1 bg-white" style="">
              <input class="form-control mr-2 search-bar" type="search" placeholder="Search by Alias" aria-label="Search">
              <button class="btn btn-primary my-1 my-sm-0" type="submit">Search</button>
            </form>
          </div>
        </div>
        <div class="card">
          <canvas id="myChartSync" width="100" height="38" phx-hook="chartHook" data-json=
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
                  "value": 50,
                  "image": "https://picsum.photos/30/30?random=5",
                  "backgroundColor": "#ffb9b2"
                }
                ]
              }
            }'
          ></canvas>
          <div class="ml-4 mt-4">
          <nav aria-label="Page navigation example">
            <ul class="pagination">
              <li class="page-item"><a class="page-link" href="#">First</a></li>
              <li class="page-item">
                <a class="page-link" href="#" aria-label="Previous">
                  <span aria-hidden="true">&laquo;</span>
                  <span class="sr-only">Previous</span>
                </a>
              </li>
              <li class="page-item"><a class="page-link" href="#">1</a></li>
              <li class="page-item"><a class="page-link" href="#">2</a></li>
              <li class="page-item"><a class="page-link" href="#">3</a></li>
              <li class="page-item">
                <a class="page-link" href="#" aria-label="Next">
                  <span aria-hidden="true">&raquo;</span>
                  <span class="sr-only">Next</span>
                </a>
              </li>
              <li class="page-item"><a class="page-link" href="#">Last</a></li>
            </ul>
          </nav>
        </div>
          <%= Enum.at(@charts, @page, "NULL!") %>
          <ul class="pagination">
            <%= for page_number <- 0..(length(@charts) - 1) do %>
            <li class="page-item">
              <a class="page-link" phx-click="pagination" phx-value-page="<%=page_number%>" href="#">
                <%=page_number + 1%>
              </a>
            </li>
            <% end%>
          </ul>
        </div>
      </div>

      <!-- section 3: Social Activity -->
        <div class="wrapper mt-5">
        <div class="row mb-4 mt-2">
          <div class="col-lg-2 col-md-6 col-sm-12 p-12">
            <img class="img-responsive" src="/images/icons/social_activity.png" alt="Distance Icon" style="max-width:200px;">
          </div>
          <div class="col-lg-4 col-md-6 col-sm-6">
            <div class="" style="max-width: 100%;">
              <div class="p-2 admin-btn-bg-container">
                <%= live_component(@socket, OmegaBraveraWeb.TimeRangeFilters) %>
              </div>
            </div>
          </div>
          <div class="col-lg-6 col-md-12 col-sm-6 py-1">
            <form class="form-inline search-bar-container p-1 my-1 my-lg-1 bg-white" style="">
              <input class="form-control mr-2 search-bar" type="search" placeholder="Search by Alias" aria-label="Search">
              <button class="btn btn-primary my-1 my-sm-0" type="submit">Search</button>
            </form>
          </div>
        </div>
      <div class="card">
        <canvas id="myChartSocial" width="100" height="38" phx-hook="chartHook" data-json=
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
                "value": 50,
                "image": "https://picsum.photos/30/30?random=5",
                "backgroundColor": "#ffb9b2"
              }
              ]
            }
          }'
        ></canvas>
        <div class="ml-4 mt-4">
        <nav aria-label="Page navigation example">
          <ul class="pagination">
            <li class="page-item"><a class="page-link" href="#">First</a></li>
            <li class="page-item">
              <a class="page-link" href="#" aria-label="Previous">
                <span aria-hidden="true">&laquo;</span>
                <span class="sr-only">Previous</span>
              </a>
            </li>
            <li class="page-item"><a class="page-link" href="#">1</a></li>
            <li class="page-item"><a class="page-link" href="#">2</a></li>
            <li class="page-item"><a class="page-link" href="#">3</a></li>
            <li class="page-item">
              <a class="page-link" href="#" aria-label="Next">
                <span aria-hidden="true">&raquo;</span>
                <span class="sr-only">Next</span>
              </a>
            </li>
            <li class="page-item"><a class="page-link" href="#">Last</a></li>
          </ul>
        </nav>
      </div>
        <%= Enum.at(@charts, @page, "NULL!") %>
        <ul class="pagination">
          <%= for page_number <- 0..(length(@charts) - 1) do %>
          <li class="page-item">
            <a class="page-link" phx-click="pagination" phx-value-page="<%=page_number%>" href="#">
              <%=page_number + 1%>
            </a>
          </li>
          <% end%>
        </ul>
      </div>
    </div>

    </div>
    """
  end
end
