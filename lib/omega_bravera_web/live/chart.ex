defmodule OmegaBraveraWeb.Chart do
  use OmegaBraveraWeb, :live_view

  alias Contex.{Dataset, Plot, BarChart}

  @per_page 20

  def mount(_params, session, socket) do
    partner_id = Map.get(session["router_params"], "id")

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

  def render(assigns) do
    ~L"""
    <p>+++Search+++</p>
    <div class="p-2">
      <%= live_component(@socket, OmegaBraveraWeb.TimeRangeFilters) %>
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
    """
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
end
