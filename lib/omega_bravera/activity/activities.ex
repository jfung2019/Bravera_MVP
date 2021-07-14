defmodule OmegaBravera.Activity.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  alias OmegaBravera.Repo

  alias OmegaBravera.Activity.ActivityAccumulator

  def create_activity(activity, user) do
    changeset =
      if Map.has_key?(activity, :admin_id) do
        ActivityAccumulator.create_activity_by_admin_changeset(activity, user, activity.admin_id)
      else
        ActivityAccumulator.create_changeset(activity, user)
      end

    Repo.insert(changeset)
  end

  def get_activity!(id) do
    from(a in ActivityAccumulator, where: a.id == ^id) |> Repo.one()
  end

  def create_app_activity(activity_attrs, user_id, device_id, user_activities) do
    ActivityAccumulator.create_bravera_app_activity(
      activity_attrs,
      user_id,
      device_id,
      user_activities
    )
    |> Repo.insert()
  end

  def create_bravera_pedometer_activity(activity_attrs, user_id, device_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :activity,
      ActivityAccumulator.create_bravera_pedometer_activity(activity_attrs, user_id, device_id)
    )
    |> Ecto.Multi.run(:point, fn _repo, %{activity: activity} ->
      OmegaBravera.Points.add_points_to_user_from_activity(activity)
    end)
    |> Repo.transaction()
  end

  def get_user_activities_at_time(
        %{start_date: start_date, end_date: end_date},
        user_id,
        device_id
      ) do
    from(
      a in ActivityAccumulator,
      where:
        a.user_id == ^user_id and
          a.device_id == ^device_id,
      where: a.start_date >= ^start_date,
      where: a.start_date <= ^end_date,
      where: not is_nil(a.device_id) == true,
      select: count(a.id)
    )
    |> Repo.one()
  end

  def get_latest_device_activity(user_id) do
    from(a in ActivityAccumulator,
      where: a.user_id == ^user_id and not is_nil(a.device_id),
      order_by: [desc: a.end_date],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  get the activity insight for a user in a period (weekly, monthly, yearly)
  """
  def get_activity_insight(period, date, user_id) do
    %{period_beginning: period_beginning, period_end: period_end} =
      get_insight_period(date, period)

    %{period_beginning: last_period_beginning, period_end: last_period_end} =
      get_last_insight_period(date, period)

    activities =
      distance_summary_query(period, user_id, period_beginning, period_end)
      |> Repo.all()

    this_period_distance = get_total_distance_over_period(period_beginning, period_end, user_id)

    last_period_distance =
      get_total_distance_over_period(last_period_beginning, last_period_end, user_id)

    this_period_average =
      this_period_distance / (Timex.diff(period_end, period_beginning, :days) + 1)

    last_period_average =
      last_period_distance / (Timex.diff(last_period_end, last_period_beginning, :days) + 1)

    {:ok,
     %{
       distance_by_date: activities,
       average_distance: this_period_average,
       total_distance: this_period_distance,
       distance_compare: calculate_distance_compare(this_period_average, last_period_average)
     }}
  end

  def calculate_distance_compare(this_period_average, last_period_average) do
    if last_period_average > 0 do
      (this_period_average - last_period_average) / last_period_average * 100
    else
      0.0
    end
  end

  defp get_total_distance_over_period(period_beginning, period_end, user_id) do
    from(a in ActivityAccumulator,
      where:
        a.user_id == ^user_id and
          fragment(
            "? between ? and ?",
            a.start_date,
            ^period_beginning,
            ^period_end
          ),
      select: coalesce(sum(a.distance), 0.0)
    )
    |> Repo.one()
  end

  defp get_insight_period(date, :weekly),
    do: %{period_beginning: Timex.beginning_of_week(date), period_end: Timex.end_of_week(date)}

  defp get_insight_period(date, :monthly),
    do: %{period_beginning: Timex.beginning_of_month(date), period_end: Timex.end_of_month(date)}

  defp get_insight_period(date, :yearly),
    do: %{period_beginning: Timex.beginning_of_year(date), period_end: Timex.end_of_year(date)}

  def get_last_insight_period(date, period) do
    case period do
      :weekly ->
        Timex.beginning_of_week(date)

      :monthly ->
        Timex.beginning_of_month(date)

      :yearly ->
        Timex.beginning_of_year(date)
    end
    |> Timex.shift(days: -1)
    |> get_insight_period(period)
  end

  defp distance_summary_query(:yearly, user_id, period_beginning, period_end) do
    from(a in ActivityAccumulator,
      right_join:
        period in fragment(
          "select generate_series(?::timestamp, ?::timestamp, '1 month')::date AS date",
          ^period_beginning,
          ^period_end
        ),
      on:
        fragment("to_char(?::date, 'YYYY-MM') = to_char(date, 'YYYY-MM')", a.start_date) and
          a.user_id == ^user_id,
      group_by: period.date,
      order_by: period.date,
      select: %{
        date: fragment("?::date", period.date),
        distance:
          fragment(
            "? / (date_part('days', date_trunc('month', ?) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL))",
            coalesce(sum(a.distance), 0.0),
            period.date
          )
      }
    )
  end

  defp distance_summary_query(_period, user_id, period_beginning, period_end) do
    from(a in ActivityAccumulator,
      right_join:
        period in fragment(
          "select generate_series(?::timestamp, ?::timestamp, '1 day')::date AS date",
          ^period_beginning,
          ^period_end
        ),
      on: fragment("?::date = date", a.start_date) and a.user_id == ^user_id,
      group_by: period.date,
      order_by: period.date,
      select: %{
        date: fragment("?::date", period.date),
        distance: coalesce(sum(a.distance), 0.0)
      }
    )
  end
end
