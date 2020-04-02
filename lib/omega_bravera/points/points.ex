defmodule OmegaBravera.Points do
  @moduledoc """
  Points Context.
  """
  import Ecto.Query

  alias OmegaBravera.{Repo}
  alias OmegaBravera.Points.Point

  @doc """
  Creates a changeset from a Point struct.
  Used in new form for admin panel.
  """
  def change_point(%Point{} = point), do: Point.changeset(point)

  def create_points_from_activity(activity, user_with_points) do
    %Point{}
    |> Point.activity_points_changeset(activity, user_with_points)
    |> Repo.insert()
  end

  def create_bonus_points(attrs \\ %{}) do
    %Point{}
    |> Point.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get a breakdown of all points in a certain day by a user.
  """
  def point_breakdown_by_day(day, user_id) do
    from(p in Point,
      where: p.user_id == ^user_id and fragment("cast(? as date)", p.inserted_at) == ^day
    )
    |> Repo.all()
  end

  @doc """
  Gets total points for user minus any spent points.
  """
  def total_points(user_id),
    do:
      Repo.aggregate(
        from(p in Point, where: p.user_id == ^user_id, select: coalesce(p.value, 0.0)),
        :sum,
        :value
      ) || Decimal.from_float(0.0)

  @doc """
  Gets summary by day of user points with the points separated out.
  """
  def user_points_history_summary(user_id) do
    from(
      p in Point,
      where: p.user_id == ^user_id,
      order_by: [desc: fragment("CAST(? AS DATE)", p.inserted_at)],
      group_by: fragment("CAST(? AS DATE)", p.inserted_at),
      select: %{
        neg_value: fragment("sum(case when ? < 0 then ? else 0 end)", p.value, p.value),
        pos_value: fragment("sum(case when ? > 0 then ? else 0 end)", p.value, p.value),
        inserted_at: fragment("CAST(? AS DATE)", p.inserted_at)
      }
    )
    |> Repo.all()
  end

  def get_user_points_one_week(user_id) do
    today = Timex.now() |> DateTime.to_date()
    one_week_ago = today |> Timex.shift(days: -7)

    from(p in Point,
      where:
        fragment("cast(? as date) BETWEEN ? and ?", p.inserted_at, ^one_week_ago, ^today) and
          p.user_id == ^user_id,
      select: %{value: sum(p.value), day: fragment("cast(inserted_at as date) as day")},
      group_by: fragment("day")
    )
    |> Repo.all()
  end

  def do_deduct_points_from_user(user, offer) do
    %Point{}
    |> Point.deduct_points_changeset(offer, user)
    |> Repo.insert()
  end
end
