defmodule OmegaBraveraWeb.OrgGroupLeaderboard do
  use OmegaBraveraWeb, :live_view

  alias Contex.{BarChart, Plot, Dataset}

  @filters %{
    "distance-metrics" => %{
      "one_week" => {
        OmegaBravera.Accounts,
        :api_get_leaderboard_of_partner_this_week,
        nil
      },
      "one_month" => {
        OmegaBravera.Accounts,
        :api_get_leaderboard_of_partner_this_month,
        nil
      },
      "all_time" => {
        OmegaBravera.Accounts,
        :api_get_leaderboard_of_partner_all_time,
        nil
      }
    },
    "social-metrics" => %{},
    "sync-metrics" => %{}
  }

  @per_page 30

  @impl true
  def mount(
        _params,
        %{"metrics_type" => metrics_type, "router_params" => router_params} = _session,
        socket
      ) do
    partner_id = Map.get(router_params, "id")
    leaderboard = execute_mfa(metrics_type, "one_week", partner_id)

    socket =
      socket
      |> assign(:metrics_type, metrics_type)
      |> assign(:page, 0)
      |> assign(:search, %{query: nil, value: nil})
      |> assign(:partner_id, partner_id)
      |> assign(:paginated_chart, generate_paginated_chart(leaderboard, @per_page, metrics_type))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
      <p>+++Search+++</p>

      <%= live_component(@socket,
        OmegaBraveraWeb.OrgGroupLeaderboardSearchComponent,
        id: :search_filter,
        metrics_type: @metrics_type
        )
      %>

      <%= Enum.at(@paginated_chart, @page) %>

      <ul class="pagination">
        <%= for page_num <- 0..(length(@paginated_chart) - 1) do %>
          <li class="page-item">
            <a
              class="page-link"
              href="#"
              phx-click="page_change"
              phx-value-<%=@metrics_type%>-page-num="<%=page_num%>"
            >
              <%= page_num + 1 %>
            </a>
          </li>
        <% end %>
      </ul>
    """
  end

  @impl true
  def handle_event("time_range_change", %{"distance-metrics-filter" => time_range_filter}, socket) do
    leaderboard =
      execute_mfa(
        socket.assigns.metrics_type,
        time_range_filter,
        socket.assigns.partner_id
      )

    {:noreply,
     assign(
       socket,
       %{
         paginated_chart: generate_paginated_chart(leaderboard, @per_page, time_range_filter),
         page: 0
       }
     )}
  end

  @impl true
  def handle_event("page_change", %{"distance-metrics-page-num" => page_num}, socket) do
    {:noreply, assign(socket, :page, as_integer(page_num))}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(event, label: :unmatched_event)
    IO.inspect(params, label: :unmatched_params)
    {:noreply, socket}
  end

  defp execute_mfa(metrics_type, time_range_filter, partner_id) do
    case get_in(@filters, [metrics_type, time_range_filter]) do
      nil ->
        []

      mfa ->
        apply(elem(mfa, 0), elem(mfa, 1), [as_integer(partner_id)])
    end
  end

  defp generate_paginated_chart(data, per_page, type) do
    data
    |> Enum.chunk_every(per_page)
    |> Enum.map(fn chunked -> generate_chart(chunked, type) end)
  end

  defp generate_chart(data, type) do
    key =
      case type do
        "one_month" -> :total_kilometers_this_month
        "all_time" -> :total_kilometers
        _ -> :total_kilometers_this_week
      end

    chart =
      data
      |> Enum.map(fn map ->
        y =
          map
          |> Map.get(key)
          |> Decimal.to_string()
          |> as_integer()

        {Map.get(map, :username), y}
      end)
      |> Dataset.new()
      |> BarChart.new()

    Plot.new(500, 400, chart)
    |> Plot.to_svg()
  end

  defp as_integer(string) do
    string
    |> Integer.parse()
    |> elem(0)
  end
end
