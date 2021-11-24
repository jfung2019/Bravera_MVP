defmodule OmegaBraveraWeb.TimeRangeFilters do
  use OmegaBraveraWeb, :live_component

  def render(assigns) do
    ~L"""
    <div class="btn-group btn-group-toggle" data-toggle="buttons">
      <label class="btn btn-primary rounded active" style="margin-left: 3px; margin-right: 3px;"><input type="radio" autocomplete="off" checked phx-click=<%="time_range_changed_"<> assigns.for %>
      phx-value-filter="week">7 Days</label>
      <label class="btn btn-primary rounded">
        <input type="radio" phx-click=<%="time_range_changed_" <> assigns.for %>
        phx-value-filter="month"
      >
      Month
      </label>
      <label class="btn btn-primary rounded" style="margin-left: 3px; margin-right: 3px;">
        <input type="radio" phx-click=<%="time_range_changed_" <> assigns.for %>
        phx-value-filter="alltime"
      >
      All time
      </label>
    </div>
    """
  end
end
