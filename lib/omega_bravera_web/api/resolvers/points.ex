defmodule OmegaBraveraWeb.Api.Resolvers.Points do
  alias OmegaBravera.Points

  def latest_points_with_history(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do:
      {:ok,
       %{
         balance: Points.total_points(user_id),
         history: Points.user_points_history_summary(user_id)
       }}

  def point_breakdown_by_day(_root, %{day: day}, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Points.point_breakdown_by_day(day, user_id)}
end
