defmodule OmegaBraveraWeb.DistanceRangeOrgFilters do
  use OmegaBraveraWeb, :live_component

  def render(assigns) do
    ~L"""
    <div class="label-group-filter" style="max-width: 100%; background-color: rgb(221,218,218);">
        <ul style="list-style: none; margin-left: -40px;">
            <li class="canvas-button p-2 <%= if @filter == "longest", do: " active" %>" phx-click="<%= "distance_range_changed_" <> @for %>" phx-value-filter="longest">
                <span class="dot" style="height: 16px; width:16px; background-color: #C50718; border-radius: 50%; display: inline-block;"></span>
                <span class="">
                    <span style="font-size: 16px; font-style: normal; line-height: 18.75px;">
                    <%= case @org_users_distance_filter do %>
                        <% "week" -> %>
                        Longest: 50+ km
                        <% "month" -> %>
                        Longest: 200+ km
                        <% "alltime" -> %>
                        Longest: 8,000+ km
                    <% end %>
                    </span>
                    <small class="canvas-text-muted">
                        <p style="margin-left: 20px; margin-bottom: 0;">no. users</p>
                    </small>
                </span>
            </li>
            <li class="canvas-button p-2 <%= if @filter == "long", do: " active" %>" phx-click="<%= "distance_range_changed_" <> @for %>" phx-value-filter="long">
                <span class="dot" style="height: 16px; width:16px; background-color: #3D4EE5; border-radius: 50%; display: inline-block;"></span>
                <span style="font-size: 16px; font-style: normal; line-height: 18.75px;">
                <%= case @org_users_distance_filter do %>
                    <% "week" -> %>
                    Long: 36 - 50km
                    <% "month" -> %>
                    Long: 141 - 200km
                    <% "alltime" -> %>
                    Long: 5,000+ km
                <% end %>
                </span>
                <small class="canvas-text-muted">
                    <p style="margin-left: 20px; margin-bottom: 0;">no. users</p>
                </small>
            </li>
            <li class="canvas-button p-2 <%= if @filter == "moderate", do: " active" %>" phx-click="<%= "distance_range_changed_" <> @for %>" phx-value-filter="moderate">
                <span class="dot" style="height: 16px; width:16px; background-color: #CDF4AE; border-radius: 50%; display: inline-block;"></span>
                <span style="font-size: 16px; font-style: normal; line-height: 18.75px;">
                <%= case @org_users_distance_filter do %>
                <% "week" -> %>
                    Moderate: 21 - 35km
                    <% "month" -> %>
                    Moderate: 61 - 140km
                    <% "alltime" -> %>
                    Moderate: 3,000+ km
                <% end %>
                </span>
                <small class="canvas-text-muted">
                    <p style="margin-left: 20px; margin-bottom: 0;">no. users</p>
                </small>
            </li>
            <li class="canvas-button p-2 <%= if @filter == "low", do: " active" %>" phx-click="<%= "distance_range_changed_" <> @for %>" phx-value-filter="low">
              <span class="dot" style="height: 16px; width:16px; background-color: #FFF1CC; border-radius: 50%; display: inline-block;"></span>
                <span style="font-size: 16px; font-style: normal; line-height: 18.75px;">
                <%= case @org_users_distance_filter do %>
                    <% "week" -> %>
                    Low: 0 - 20km
                    <% "month" -> %>
                    Low: 0 - 80km
                    <% "alltime" -> %>
                    Low: 1,000+ km
                <% end %>
                </span>
                <small class="canvas-text-muted">
                    <p style="margin-left: 20px; margin-bottom: 0;">no. users</p>
                </small>
            </li>
        </ul>
    </div>
    """
  end
end
