defmodule OmegaBraveraWeb.TimeRangeFilters do
  use OmegaBraveraWeb, :live_component

  def render(assigns) do
    ~L"""
    <button class="btn btn-info"
      type="button"
      phx-click="time_range_changed"
      phx-value-filter="week"
    >
    7 Days
    </button>

    <button class="btn btn-danger"
      type="button"
      phx-click="time_range_changed"
      phx-value-filter="month"
    >
    Month
    </button>

    <button class="btn btn-success"
      type="button"
      phx-click="time_range_changed"
      phx-value-filter="alltime"
    >
    All time
    </button>
    """
  end
end
