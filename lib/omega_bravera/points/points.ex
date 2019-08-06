defmodule OmegaBravera.Points do
  @moduledoc """
  Points Context.
  """
  import Ecto.Query

  alias OmegaBravera.{Repo}
  alias OmegaBravera.Points.Point

  def create_points_from_activity(activity, user_with_points) do
    %Point{}
    |> Point.activity_points_changeset(activity, user_with_points)
    |> Repo.insert()
  end

  # def create_points_from_referral() do

  # end

  # def create_bonus_points() do

  # end

  def get_user_points(user_id) do
    from(
      p in Point,
      where: p.user_id == ^user_id,
      group_by: p.user_id,
      select: sum(p.balance)
    )
    |> Repo.one()
  end
end
