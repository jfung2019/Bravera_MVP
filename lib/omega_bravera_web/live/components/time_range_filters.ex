defmodule OmegaBraveraWeb.TimeRangeFilters do
  use OmegaBraveraWeb, :live_component

  def render(assigns) do
    ~L"""
    <div class="btn-group btn-group-toggle filterNav" style="margin-left: 5px; margin-right:5px;">
      <label class="btn btn-primary rounded<%= if @filter == "week", do: " active" %>">
        <input type="radio" phx-click="<%= "time_range_changed_" <> @for %>" phx-value-filter="week">
        7 Days
      </label>
      <label class="btn btn-primary rounded<%= if @filter == "month", do: " active" %>">
        <input type="radio" phx-click="<%= "time_range_changed_" <> @for %>" phx-value-filter="month">
        30 Days
      </label>
      <label class="btn btn-primary rounded<%= if @filter == "alltime", do: " active" %>" >
        <input type="radio" phx-click="<%= "time_range_changed_" <> @for %>" phx-value-filter="alltime">
        All time
      </label>
    </div>
    """
  end
end
