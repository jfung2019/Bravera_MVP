defmodule OmegaBraveraWeb.TimeRangeFilters do
  use OmegaBraveraWeb, :live_component

  def render(assigns) do
    ~L"""
    <button class="btn admin-btn-bg rounded"
      type="button"
      phx-click=<%="time_range_changed_" <> assigns.for %>
      phx-value-filter="week"
    >
    7 Days
    </button>

    <button class="btn admin-btn-bg rounded"
      type="button"
      phx-click=<%="time_range_changed_" <> assigns.for %>
      phx-value-filter="month"
    >
    Month
    </button>

    <button class="btn admin-btn-bg rounded"
      type="button"
      phx-click=<%="time_range_changed_" <> assigns.for %>
      phx-value-filter="alltime"
    >
    All time
    </button>
    """
  end
end
