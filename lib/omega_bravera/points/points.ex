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
    attrs = Map.put(attrs, "source", "admin")

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
end
