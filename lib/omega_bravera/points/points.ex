defmodule OmegaBravera.Points do
  @moduledoc """
  Points Context.
  """
  import Ecto.Query

  alias OmegaBravera.{Repo}
  alias OmegaBravera.Points.Point

  def change_point(%Point{} = point) do
    Point.changeset(point)
  end

  def create_points_from_activity(activity, user_with_points) do
    %Point{}
    |> Point.activity_points_changeset(activity, user_with_points)
    |> Repo.insert()
  end

  # def create_points_from_referral() do

  # end

  def create_bonus_points(attrs \\ %{}) do
    %Point{}
    |> Point.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_points(user_id) do
    points =
      from(
        p in Point,
        where: p.user_id == ^user_id,
        group_by: p.user_id,
        select: sum(p.value)
      )
      |> Repo.one()

    if is_nil(points) do
      Decimal.new(0)
    else
      points
    end
  end

  def get_user_points_one_week(user_id) do
    today = Timex.now() |> DateTime.to_date()
    one_week_ago = today |> Timex.shift(days: -7)

    from(p in Point,
      where:
        fragment("cast(? as date) BETWEEN ? and ?", p.inserted_at, ^today, ^one_week_ago) and
          p.user_id == ^user_id,
      select: %{value: sum(p.value), day: fragment("cast(inserted_at as date) as day")},
      group_by: fragment("day")
    )
    |> Repo.all()
  end

  # select sum(value), cast(inserted_at as date) as day
  # from points where user_id = 40 and value > 0 and
  # inserted_at between '2020-03-04' and '2020-03-11' group by day;

  def do_deduct_points_from_user(user, offer) do
    %Point{}
    |> Point.deduct_points_changeset(offer, user)
    |> Repo.insert()
  end
end
