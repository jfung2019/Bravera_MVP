defmodule OmegaBraveraWeb.OrgDashboardChartLive do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.Accounts

  @per_page 10

  def mount(_params, %{"organization_id" => organization_id}, socket) do
    org_users_group_distance =
      organization_id
      |> Accounts.get_dashboard_org_week_group()

    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_week_longest()
      |> format_paginate()

    current_page = 0

    socket =
      socket
      |> assign(
        org_users_group_distance: %{
          encoded: Jason.encode!(org_users_group_distance)
        },
        user_pagination: %{
          total_pages: get_total_pages(org_users_distance),
          current_page: current_page,
          org_users_distance_data: paginate(org_users_distance, current_page)
        },
        org_users_distance: org_users_distance,
        org_users_distance_filter: "week",
        org_users_distance_details_filter: "longest",
        organization_id: organization_id
      )

    {:ok, socket}
  end

  # def handle_event("time_range_changed_org_distance", %{"filter" => duration}, socket) do
  #   org_users_group_distance =
  #     case duration do
  #       "week" ->
  #         socket.assigns.organization_id
  #         |> Accounts.get_dashboard_org_week_group()

  #       "month" ->
  #         socket.assigns.organization_id
  #         |> Accounts.get_dashboard_org_month_group()

  #       "alltime" ->
  #         socket.assigns.organization_id
  #         |> Accounts.get_dashboard_org_all_time_group()
  #     end

  #   {:noreply,
  #    socket
  #    |> assign(
  #      org_users_group_distance: %{
  #        encoded: Jason.encode!(org_users_group_distance)
  #      },
  #      org_users_distance_filter: duration
  #    )}
  # end

  def handle_event("time_range_changed_org_distance", %{"filter" => "week"}, %{assigns: %{organization_id: organization_id}}= socket) do

    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_week_longest()
      |> format_paginate()

    {:noreply, assign(socket,
           org_users_group_distance: %{
             encoded: Jason.encode!(Accounts.get_dashboard_org_week_group(organization_id))
           },
           user_pagination: %{
            total_pages: get_total_pages(org_users_distance),
            current_page: 0,
            org_users_distance_data: paginate(org_users_distance, 0)
          },
          org_users_distance: org_users_distance,
          org_users_distance_details_filter: "longest",
          org_users_distance_filter: "week")}
  end

  def handle_event("time_range_changed_org_distance", %{"filter" => "month"}, %{assigns: %{organization_id: organization_id}}= socket) do

    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_month_longest()
      |> format_paginate()

    {:noreply, assign(socket,
           org_users_group_distance: %{
             encoded: Jason.encode!(Accounts.get_dashboard_org_month_group(organization_id))
           },
           user_pagination: %{
            total_pages: get_total_pages(org_users_distance),
            current_page: 0,
            org_users_distance_data: paginate(org_users_distance, 0)
          },
          org_users_distance: org_users_distance,
          org_users_distance_details_filter: "longest",
          org_users_distance_filter: "month")}
  end

  def handle_event("time_range_changed_org_distance", %{"filter" => "alltime"}, %{assigns: %{organization_id: organization_id}}= socket) do

    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_month_longest()
      |> format_paginate()

    {:noreply, assign(socket,
           org_users_group_distance: %{
             encoded: Jason.encode!(Accounts.get_dashboard_org_all_time_group(organization_id))
           },
           user_pagination: %{
            total_pages: get_total_pages(org_users_distance),
            current_page: 0,
            org_users_distance_data: paginate(org_users_distance, 0)
          },
          org_users_distance: org_users_distance,
          org_users_distance_details_filter: "longest",
          org_users_distance_filter: "alltime")}
  end

  # week
  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "longest"},
        %{
          assigns: %{
            org_users_distance_filter: "week",
            organization_id: organization_id
          }
        } = socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_week_longest()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "longest"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "long"},
        %{assigns: %{org_users_distance_filter: "week", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_week_long()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "long"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "moderate"},
        %{assigns: %{org_users_distance_filter: "week", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_week_moderate()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "moderate"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "low"},
        %{assigns: %{org_users_distance_filter: "week", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_week_low()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
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
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_month_longest()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "longest"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "long"},
        %{assigns: %{org_users_distance_filter: "month", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_month_long()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "long"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "moderate"},
        %{assigns: %{org_users_distance_filter: "month", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_month_moderate()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "moderate"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "low"},
        %{assigns: %{org_users_distance_filter: "month", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_month_low()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
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
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_all_time_longest()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "longest"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "long"},
        %{assigns: %{org_users_distance_filter: "alltime", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_all_time_long()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "long"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "moderate"},
        %{assigns: %{org_users_distance_filter: "alltime", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_all_time_moderate()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "moderate"
     )}
  end

  def handle_event(
        "distance_range_changed_org_distance_details",
        %{"filter" => "low"},
        %{assigns: %{org_users_distance_filter: "alltime", organization_id: organization_id}} =
          socket
      ) do
    org_users_distance =
      organization_id
      |> Accounts.get_dashboard_org_all_time_low()
      |> format_paginate()

    {:noreply,
     assign(socket,
       user_pagination: %{
         total_pages: get_total_pages(org_users_distance),
         current_page: 0,
         org_users_distance_data: paginate(org_users_distance, 0)
       },
       org_users_distance: org_users_distance,
       org_users_distance_details_filter: "low"
     )}
  end

  def handle_event("paginate_distance", %{"page" => page}, socket) do
    {page, _} = Integer.parse(page)
    IO.puts("called!")
    IO.inspect(socket.assigns.org_users_distance)

    {:noreply,
     socket
     |> assign(
       user_pagination: %{
         socket.assigns.user_pagination
         | current_page: page,
           org_users_distance_data: paginate(socket.assigns.org_users_distance, page)
       }
     )}
  end

  def handle_event(
        "paginate_distance_next",
        _params,
        %{assigns: %{user_pagination: current_pagination}} = socket
      ) do
    current_pagination = current_pagination
    socket.assigns.user_pagination

    if current_pagination.current_page >= current_pagination.total_pages - 1 do
      {:noreply, socket}
    else
      previous_page = current_pagination.current_page + 1

      {:noreply,
       socket
       |> assign(
         user_pagination: %{
           current_pagination
           | current_page: previous_page,
             org_users_distance_data: paginate(socket.assigns.org_users_distance, previous_page)
         }
       )}
    end
  end

  def handle_event(
        "paginate_distance_previous",
        _params,
        %{assigns: %{user_pagination: current_pagination}} = socket
      ) do
    current_pagination = current_pagination
    socket.assigns.user_pagination

    if current_pagination.current_page <= 0 do
      {:noreply, socket}
    else
      previous_page = current_pagination.current_page - 1

      {:noreply,
       socket
       |> assign(
         user_pagination: %{
           current_pagination
           | current_page: previous_page,
             org_users_distance_data: paginate(socket.assigns.org_users_distance, previous_page)
         }
       )}
    end
  end

  defp paginate({}, _current_page) do
    []
  end

  defp paginate(data, current_page) do
    data
    |> elem(current_page)
  end

  defp format_paginate(data) do
    data
    |> Enum.chunk_every(@per_page)
    |> List.to_tuple()
  end

  defp get_total_pages(data) do
    tuple_size(data)
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
            <%= for user <- @user_pagination.org_users_distance_data do %>
            <tr>
              <td><%= user.username %></td>
              <td><%= user.distance %></td>
              <td> null </td>
            </tr>
            <% end %>
          </tbody>
        </table>
         <%= if @user_pagination.total_pages != 0 do %>
            <div class="mt-4">
              <nav>
                <ul class="pagination flex-wrap">
                  <li class="page-item">
                    <a phx-click="paginate_distance" phx-value-page="0" class="page-link" href="#">First</a>
                  </li>
                  <li class="page-item">
                    <a phx-click="paginate_distance_previous" class="page-link" href="#" aria-label="Previous">
                      <span aria-hidden="true">&laquo;</span>
                      <span class="sr-only">Previous</span>
                    </a>
                  </li>
                  <%= for page <- 1..@user_pagination.total_pages do %>
                    <li class="page-item">
                      <a phx-click="paginate_distance" phx-value-page="<%= page - 1 %>" class="page-link" href="#"><%= page %></a>
                      </li>
                  <% end %>
                  <li class="page-item">
                    <a phx-click="paginate_distance_next" class="page-link" href="#" aria-label="Next">
                      <span aria-hidden="true">&raquo;</span>
                      <span class="sr-only">Next</span>
                    </a>
                  </li>
                  <li class="page-item">
                    <a phx-click="paginate_distance" phx-value-page="<%= @user_pagination.total_pages - 1 %>" class="page-link" href="#">Last</a>
                  </li>
                </ul>
              </nav>
            </div>
          <% end %>
      </div>
    </div>
    """
  end
end
