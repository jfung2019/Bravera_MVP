defmodule OmegaBraveraWeb.OrgGroupLeaderboardsLive do
  use OmegaBraveraWeb, :live_view
  alias OmegaBravera.Accounts
  alias OmegaBravera.Accounts.User

  @per_page 10

  def mount(%{"id" => partner_id}, session, socket) do
    distance_data =
      partner_id
      |> Accounts.api_get_leaderboard_of_partner_this_week()
      |> get_distance_data(:total_kilometers_this_week)
      |> format_paginate()

    social_data =
      partner_id
      |> Accounts.get_leaderboad_partner_messages_this_week()
      |> get_social_data()
      |> format_paginate()

    current_page = 0

    socket =
      socket
      |> assign(parent_params: Map.get(session, "router_params", %{}), partner_id: partner_id)
      |> assign(:distance_pagination, %{
        total_pages: get_total_pages(distance_data),
        current_page: current_page,
        encoded: Jason.encode!(paginate(distance_data, current_page))
      })
      |> assign(
        social_pagination: %{
          total_pages: get_total_pages(social_data),
          current_page: current_page,
          encoded: Jason.encode!(paginate(social_data, current_page))
        },
        distance_data: distance_data,
        social_data: social_data,
        distance_search: "",
        social_search: "",
        distance_filter: "week",
        social_filter: "week"
      )

    {:ok, socket}
  end

  def handle_event(
        "social_search",
        %{"search_input" => input},
        %{assigns: %{social_data: social_data}} = socket
      ) do
    social_data =
      social_data
      |> search(input)
      |> format_paginate()

    {:noreply,
     socket
     |> assign(
       social_pagination: %{
         total_pages: get_total_pages(social_data),
         current_page: 0,
         encoded: Jason.encode!(paginate(social_data, 0))
       },
       social_data: social_data,
       social_search: input
     )}
  end

  def handle_event(
        "distance_search",
        %{"search_input" => input},
        %{assigns: %{distance_data: distance_data}} = socket
      ) do
    distance_data =
      distance_data
      |> search(input)
      |> format_paginate()

    {:noreply,
     socket
     |> assign(
       distance_pagination: %{
         total_pages: get_total_pages(distance_data),
         current_page: 0,
         encoded: Jason.encode!(paginate(distance_data, 0))
       },
       distance_data: distance_data,
       distance_search: input
     )}
  end

  def handle_event(
        "paginate_social_next",
        _params,
        %{assigns: %{social_pagination: current_pagination}} = socket
      ) do
    current_pagination = current_pagination
    socket.assigns.social_pagination

    if current_pagination.current_page >= current_pagination.total_pages - 1 do
      {:noreply, socket}
    else
      previous_page = current_pagination.current_page + 1

      {:noreply,
       socket
       |> assign(:social_pagination, %{
         current_pagination
         | current_page: previous_page,
           encoded: Jason.encode!(paginate(socket.assigns.social_data, previous_page))
       })}
    end
  end

  def handle_event(
        "paginate_social_previous",
        _params,
        %{assigns: %{social_pagination: current_pagination}} = socket
      ) do
    current_pagination = current_pagination
    socket.assigns.social_pagination

    if current_pagination.current_page <= 0 do
      {:noreply, socket}
    else
      previous_page = current_pagination.current_page - 1

      {:noreply,
       socket
       |> assign(:social_pagination, %{
         current_pagination
         | current_page: previous_page,
           encoded: Jason.encode!(paginate(socket.assigns.social_data, previous_page))
       })}
    end
  end

  def handle_event("paginate_social", %{"page" => page}, socket) do
    {page, _} = Integer.parse(page)

    {:noreply,
     socket
     |> assign(:social_pagination, %{
       socket.assigns.social_pagination
       | current_page: page,
         encoded: Jason.encode!(paginate(socket.assigns.social_data, page))
     })}
  end

  def handle_event(
        "paginate_distance_next",
        _params,
        %{assigns: %{distance_pagination: current_pagination}} = socket
      ) do
    current_pagination = current_pagination
    socket.assigns.distance_pagination

    if current_pagination.current_page >= current_pagination.total_pages - 1 do
      {:noreply, socket}
    else
      previous_page = current_pagination.current_page + 1

      {:noreply,
       socket
       |> assign(:distance_pagination, %{
         current_pagination
         | current_page: previous_page,
           encoded: Jason.encode!(paginate(socket.assigns.distance_data, previous_page))
       })}
    end
  end

  def handle_event(
        "paginate_distance_previous",
        _params,
        %{assigns: %{distance_pagination: current_pagination}} = socket
      ) do
    current_pagination = current_pagination
    socket.assigns.distance_pagination

    if current_pagination.current_page <= 0 do
      {:noreply, socket}
    else
      previous_page = current_pagination.current_page - 1

      {:noreply,
       socket
       |> assign(:distance_pagination, %{
         current_pagination
         | current_page: previous_page,
           encoded: Jason.encode!(paginate(socket.assigns.distance_data, previous_page))
       })}
    end
  end

  def handle_event("paginate_distance", %{"page" => page}, socket) do
    {page, _} = Integer.parse(page)

    {:noreply,
     socket
     |> assign(:distance_pagination, %{
       socket.assigns.distance_pagination
       | current_page: page,
         encoded: Jason.encode!(paginate(socket.assigns.distance_data, page))
     })}
  end

  def handle_event("time_range_changed_social", %{"filter" => duration}, socket) do
    social_data =
      case duration do
        "week" ->
          socket.assigns.partner_id
          |> Accounts.get_leaderboad_partner_messages_this_week()
          |> get_social_data()
          |> format_paginate()

        "month" ->
          socket.assigns.partner_id
          |> Accounts.get_leaderboad_partner_messages_this_month()
          |> get_social_data()
          |> format_paginate()

        "alltime" ->
          socket.assigns.partner_id
          |> Accounts.get_leaderboad_partner_messages_all_time()
          |> get_social_data()
          |> format_paginate()
      end

    {:noreply,
     socket
     |> assign(
       social_pagination: %{
         total_pages: get_total_pages(social_data),
         current_page: 0,
         encoded: Jason.encode!(paginate(social_data, 0))
       },
       social_data: social_data,
       social_filter: duration
     )}
  end

  def handle_event("time_range_changed_distance", %{"filter" => duration}, socket) do
    distance_data =
      case duration do
        "week" ->
          socket.assigns.partner_id
          |> Accounts.api_get_leaderboard_of_partner_this_week()
          |> get_distance_data(:total_kilometers_this_week)
          |> format_paginate()

        "month" ->
          socket.assigns.partner_id
          |> Accounts.api_get_leaderboard_of_partner_this_month()
          |> get_distance_data(:total_kilometers_this_month)
          |> format_paginate()

        "alltime" ->
          socket.assigns.partner_id
          |> Accounts.api_get_leaderboard_of_partner_all_time()
          |> get_distance_data(:total_kilometers)
          |> format_paginate()
      end

    {:noreply,
     socket
     |> assign(
       distance_pagination: %{
         total_pages: get_total_pages(distance_data),
         current_page: 0,
         encoded: Jason.encode!(paginate(distance_data, 0))
       },
       distance_data: distance_data,
       distance_filter: duration
     )}
  end

  defp search(data, term) do
    data
    |> Tuple.to_list()
    |> List.flatten()
    |> Enum.filter(fn elem ->
      String.contains?(String.downcase(elem.name), String.downcase(term))
    end)
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

  defp get_distance_data(data, key) do
    data
    |> Enum.map(fn %User{} = user ->
      %{
        name: user.username,
        value: Decimal.to_float(Map.get(user, key)),
        image: user.profile_picture,
        backgroundColor: "#ffb9b2"
      }
    end)
  end

  defp get_social_data(data) do
    data
    |> Enum.map(fn %{user: %User{} = user, message_count: message_count} ->
      %{
        name: user.username,
        value: message_count,
        image: user.profile_picture,
        backgroundColor: "#ffb9b2"
      }
    end)
  end

  def render(assigns) do
    ~L"""
    <div class="container-fluid">
     <!-- section 1: Distance-->
      <div class="wrapper">
        <div class="row mb-4 mt-2">
          <div class="col-lg-2 col-md-6 col-sm-12 p-12">
            <img class="img-responsive" src="/images/icons/distance.png" alt="Distance Icon" style="max-width:200px;">
          </div>
          <div class="col-lg-4 col-md-6 col-sm-6">
            <div class="" style="max-width: 100%;">
              <div class="p-2 admin-btn-bg-container">
                <%= live_component(@socket, OmegaBraveraWeb.TimeRangeFilters, for: "distance", filter: @distance_filter) %>
              </div>
            </div>
          </div>
          <div class="col-lg-6 col-md-12 col-sm-6 pb-1">
            <form phx-submit="distance_search" class="form-inline search-bar-container p-1 my-1 my-lg-1 search-button">
              <input name="search_input" class="form-control mr-2 search-bar" type="search" placeholder="Search by Alias" aria-label="Search" value="<%= @distance_search %>" type="text">
              <button class="btn btn-primary my-1 my-sm-0" type="submit">Search</button>
            </form>
          </div>
        </div>
        <div class="card pt-4">
          <canvas id="myChartDistance" width="100" height="38" phx-hook="distanceChartHook" data-json="<%= @distance_pagination.encoded %>"></canvas>
          <%= if @distance_pagination.total_pages != 0 do %>
            <div class="ml-4 mt-4">
              <nav aria-label="Page navigation example">
                <ul class="pagination">
                  <li class="page-item">
                    <a phx-click="paginate_distance" phx-value-page="0" class="page-link" href="#">First</a>
                  </li>
                  <li class="page-item">
                    <a phx-click="paginate_distance_previous" class="page-link" href="#" aria-label="Previous">
                      <span aria-hidden="true">&laquo;</span>
                      <span class="sr-only">Previous</span>
                    </a>
                  </li>
                  <%= for page <- 1..@distance_pagination.total_pages do %>
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
                    <a phx-click="paginate_distance" phx-value-page="<%= @distance_pagination.total_pages - 1 %>" class="page-link" href="#">Last</a>
                  </li>
                </ul>
              </nav>
            </div>
          <% end %>
        </div>
      </div>

      <!-- section 2: Social Activity -->
      <div class="wrapper mt-5">
        <div class="row mb-4 mt-2">
          <div class="col-lg-2 col-md-6 col-sm-12 p-12">
            <img class="img-responsive" src="/images/icons/social_activity.png" alt="Distance Icon" style="max-width:200px;">
          </div>
          <div class="col-lg-4 col-md-6 col-sm-6">
            <div class="" style="max-width: 100%;">
              <div class="p-2 admin-btn-bg-container">
                <%= live_component(@socket, OmegaBraveraWeb.TimeRangeFilters, for: "social", filter: @social_filter) %>
              </div>
            </div>
          </div>
          <div class="col-lg-6 col-md-12 col-sm-6 pb-1">
            <form phx-submit="social_search" class="form-inline search-bar-container p-1 my-1 my-lg-1 search-button">
              <input name="search_input" class="form-control mr-2 search-bar" placeholder="Search by Alias" aria-label="Search" value="<%= @social_search %>" type="text">
              <button class="btn btn-primary my-1 my-sm-0" type="submit">Search</button>
            </form>
          </div>
        </div>
        <div class="card pt-4 mb-4">
          <canvas id="myChartSocial" width="100" height="38" phx-hook="socialChartHook" data-json="<%= @social_pagination.encoded %>"></canvas>
          <%= if @distance_pagination.total_pages != 0 do %>
            <div class="ml-4 mt-4">
              <nav aria-label="Page navigation example">
                <ul class="pagination">
                  <li class="page-item">
                    <a phx-click="paginate_social" phx-value-page="0" class="page-link" href="#">First</a>
                  </li>
                  <li class="page-item">
                    <a phx-click="paginate_social_previous" class="page-link" href="#" aria-label="Previous">
                      <span aria-hidden="true">&laquo;</span>
                      <span class="sr-only">Previous</span>
                    </a>
                  </li>
                  <%= for page <- 1..@social_pagination.total_pages do %>
                    <li class="page-item">
                      <a phx-click="paginate_social" phx-value-page="<%= page - 1 %>" class="page-link" href="#"><%= page %></a>
                    </li>
                  <% end %>
                  <li class="page-item">
                    <a phx-click="paginate_social_next" class="page-link" href="#" aria-label="Next">
                      <span aria-hidden="true">&raquo;</span>
                      <span class="sr-only">Next</span>
                    </a>
                  </li>
                  <li class="page-item">
                    <a phx-click="paginate_social" phx-value-page="<%= @social_pagination.total_pages - 1 %>" class="page-link" href="#">Last</a>
                  </li>
                </ul>
              </nav>
            </div>
          <% end %>
      </div>
    """
  end
end
