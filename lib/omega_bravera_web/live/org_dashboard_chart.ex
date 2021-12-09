defmodule OmegaBraveraWeb.OrgDashboardChartLive do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.Accounts

  #   @per_page 10

  def mount(_params, %{"organization_id" => organization_id}, socket) do
    org_users_group_distance = Accounts.get_dashboard_org_week_group(organization_id)

    org_users_distance = Accounts.get_dashboard_org_week_longest(organization_id)

    # current_page = 0

    socket =
      socket
      |> assign(
        org_users_group_distance: %{
          encoded: Jason.encode!(org_users_group_distance)
        },
        org_users_distance: org_users_distance,
        org_users_distance_filter: "week",
        org_users_distance_details_filter: "longest",
        organization_id: organization_id
      )

    {:ok, socket}
  end

  #   def handle_event("time_range_changed_org_distance", %{"filter" => "week"}, %{assigns: %{organization_id: organization_id}}= socket) do
  #     {:ok, assign(socket, : Accounts.get_dashboard_org_week_group_query(organization_id))}
  #   end

  def handle_event("time_range_changed_org_distance", %{"filter" => duration}, socket) do
    org_users_group_distance =
      case duration do
        "week" ->
          socket.assigns.organization_id
          |> Accounts.get_dashboard_org_week_group()

        "month" ->
          socket.assigns.organization_id
          |> Accounts.get_dashboard_org_month_group()

        "alltime" ->
          socket.assigns.organization_id
          |> Accounts.get_dashboard_org_all_time_group()
      end

    {:noreply,
     socket
     |> assign(
       org_users_group_distance: %{
         encoded: Jason.encode!(org_users_group_distance)
       },
       org_users_distance_filter: duration
     )}
  end

  # week
  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "longest"},
        %{assigns: %{org_users_distance_filter: "week", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_week_longest(organization_id),
       org_users_distance_details_filter: "longest"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "long"},
        %{assigns: %{org_users_distance_filter: "week", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_week_long(organization_id),
       org_users_distance_details_filter: "long"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "moderate"},
        %{assigns: %{org_users_distance_filter: "week", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_week_moderate(organization_id),
       org_users_distance_details_filter: "moderate"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "low"},
        %{assigns: %{org_users_distance_filter: "week", organization_id: organization_id}} =
          socket
      ) do
    IO.puts("CALLED!")

    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_week_low(organization_id),
       org_users_distance_details_filter: "low"
     )}
  end

  # month
  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "longest"},
        %{assigns: %{org_users_distance_filter: "month", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_month_longest(organization_id),
       org_users_distance_details_filter: "longest"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "long"},
        %{assigns: %{org_users_distance_filter: "month", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_month_long(organization_id),
       org_users_distance_details_filter: "long"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "moderate"},
        %{assigns: %{org_users_distance_filter: "month", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_month_moderate(organization_id),
       org_users_distance_details_filter: "moderate"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "low"},
        %{assigns: %{org_users_distance_filter: "month", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_month_low(organization_id),
       org_users_distance_details_filter: "low"
     )}
  end

  # alltime
  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "longest"},
        %{assigns: %{org_users_distance_filter: "alltime", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_all_time_longest(organization_id),
       org_users_distance_details_filter: "longest"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "long"},
        %{assigns: %{org_users_distance_filter: "alltime", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_all_time_long(organization_id),
       org_users_distance_details_filter: "long"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "moderate"},
        %{assigns: %{org_users_distance_filter: "alltime", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_all_time_moderate(organization_id),
       org_users_distance_details_filter: "moderate"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "low"},
        %{assigns: %{org_users_distance_filter: "alltime", organization_id: organization_id}} =
          socket
      ) do
    {:noreply,
     assign(socket,
       org_users_distance: Accounts.get_dashboard_org_all_time_low(organization_id),
       org_users_distance_details_filter: "low"
     )}
  end

  def render(assigns) do
    ~L"""
    <div class="row">
        <div class="col-lg-3">
            <img class="img-responsive" src="/images/icons/distance_no-icon.png" alt="Distance Icon" style="max-width:190px;">
        </div>
        <div class="col-lg-9 px-2">
            <div class="btn-group btn-group-toggle filterNav" style="margin-left: 5px; margin-right: 5px; background-color: #dddada; padding: 5px;">
              <%= live_component(@socket, OmegaBraveraWeb.TimeRangeOrgFilters, for: "org_distance", filter: @org_users_distance_filter) %>
            </div>
        </div>
    </div>
    <div class="row mb-4 mt-2">
        <div class="col-lg-8 col-md-8 col-sm-12">
          <small class="text-muted">
              <p>Based on your user’s daily average during the timeframe selected. Data only includes user who synced during that timeframe. Click on the chart or the legend to view the list of users.</p>
          </small>
          <%# Canvas from liveview %>
          <canvas id="myChartOrgDistance" width="100" height="50" phx-hook="distanceChartOrgHook" data-json="<%= @org_users_group_distance.encoded %>"></canvas>
       </div>
        <%# Canvas control interface container%>
        <div class="col-lg-4 col-md-4 col-sm-12 mt-5">
          <%# Canvas control interface section%>
          <%= live_component(@socket, OmegaBraveraWeb.DistanceRangeOrgFilters, for: "org_distance_details", filter: @org_users_distance_details_filter,  org_users_distance_filter: @org_users_distance_filter) %>
      </div>
    </div>

    <div class="row" id="data-table">
      <%# show / hide data onclick from canvas interface controller %>
      <div class="col-12">
        <table class="table canvas-result-table">
            <thead>
                <tr>
                <th scope="col">Username</th>
                <th scope="col">Distance</th>
                <th scope="col">Last Active</th>
                </tr>
            </thead>
            <tbody class="content">
            <%= for user <- @org_users_distance do %>
            <tr>
              <td><%= user.username %></td>
              <td><%= user.distance %></td>
              <td> not implemented </td>
            </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
