defmodule OmegaBraveraWeb.OrgGroupLeaderboardSearchComponent do
  use OmegaBraveraWeb, :live_component

  def render(assigns) do
    ~L"""
      <button
        type="button"
        class="btn btn-info ml-2 mr-2"
        phx-click="time_range_change"
        phx-value-<%=@metrics_type%>-filter="one_week"
      >
        7 days
      </button>
      <button
        type="button"
        class="btn btn-success mr-2"
        phx-click="time_range_change"
        phx-value-<%=@metrics_type%>-filter="one_month"
      >
        1 Month
      </button>
      <button
        type="button"
        class="btn btn-danger mr-2"
        phx-click="time_range_change"
        phx-value-<%=@metrics_type%>-filter="all_time"
      >
        All Time
      </button>
    """
  end
end
