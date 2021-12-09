defmodule OmegaBraveraWeb.TimeRangeOrgFilters do
  use OmegaBraveraWeb, :live_component

  def render(assigns) do
    ~L"""
    <label class="btn btn-primary rounded <%= if @filter == "week", do: " active" %>">
        <input type="radio" phx-click="<%= "time_range_changed_" <> @for %>" phx-value-filter="week" onclick="updateLabel()">
        7 Days
    </label>
    <label class="btn btn-primary rounded <%= if @filter == "month", do: " active" %>" phx-click="<%= "time_range_changed_" <> @for %>" phx-value-filter="month">
        <input type="radio">
        30 Days
    </label>
    <label class="btn btn-primary rounded <%= if @filter == "alltime", do: " active" %>" phx-click="<%= "time_range_changed_" <> @for %>" phx-value-filter="alltime">
        <input type="radio">
        All time
    </label>
    """
  end
end
