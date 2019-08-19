defmodule OmegaBravera.Points.Point do
  @moduledoc """
  Point Schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Activity.ActivityAccumulator
  alias OmegaBravera.Activity.ActivityOptions

  @allowed_attributes [:activity_id, :user_id, :value, :source]
  @required_attributes [:user_id, :value, :source]
  @allowed_activity_types ActivityOptions.points_allowed_activities()
  @points_per_km Decimal.new(10)

  schema "points" do
    # Can be in -ve or +ve.
    field(:value, :decimal)
    # Can be redeem, activity, referral, bonus, ...
    field(:source, :string)

    timestamps(type: :utc_datetime)

    belongs_to(:user, User)
    belongs_to(:activity, ActivityAccumulator)
  end

  def activity_points_changeset(
        point,
        %ActivityAccumulator{
          id: activity_id,
          type: activity_type,
          distance: distance
        },
        %User{id: user_id, daily_points_limit: daily_points_limit, todays_points: todays_points}
      ) do
    point
    |> cast(%{}, [])
    |> put_change(:activity_id, activity_id)
    |> put_change(:user_id, user_id)
    |> put_change(:source, "activity")
    |> validate_activity_type(@allowed_activity_types, activity_type)
    |> add_value_from_distance(distance, daily_points_limit, todays_points)
    |> validate_required(@required_attributes)
  end

  def changeset(point, attrs \\ %{}) do
    IO.inspect attrs
    point
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
  end

  defp validate_activity_type(changeset, types_to_allow, activity_type) do
    if Enum.member?(types_to_allow, activity_type) do
      changeset
    else
      add_error(changeset, :id, "Cycle activities are not eligible for points")
    end
  end

  defp add_value_from_distance(changeset, distance, daily_points_limit, todays_points)
       when not is_nil(distance) do
    max_value = Decimal.mult(Decimal.new(daily_points_limit), @points_per_km)
    remaining_value_today = Decimal.sub(max_value, todays_points)

    points = distance |> Decimal.round(2, :floor) |> Decimal.mult(@points_per_km)

    cond do
      remaining_value_today == Decimal.new(0) or remaining_value_today == Decimal.from_float(0.00) ->
        add_error(changeset, :id, "User reached max points for today")

      Decimal.cmp(points, remaining_value_today) == :gt or
          Decimal.cmp(points, remaining_value_today) == :eq ->
        put_change(changeset, :value, remaining_value_today)

      Decimal.cmp(points, remaining_value_today) == :lt ->
        put_change(changeset, :value, points)
    end
  end

  defp add_value_from_distance(changeset, _, _, _), do: changeset

  def get_points_per_km(), do: @points_per_km
end
