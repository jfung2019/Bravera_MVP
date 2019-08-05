defmodule OmegaBravera.Points.Point do
  @moduledoc """
  Point Schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Activity.ActivityAccumulator
  alias OmegaBravera.Activity.ActivityOptions

  @allowed_attributes [:activity_id, :user_id, :balance, :source]
  @required_attributes [:user_id, :balance, :source]
  @allowed_activity_types ActivityOptions.points_allowed_activities()
  @points_per_km 10

  schema "points" do
    # Can be in -ve or +ve.
    field(:balance, :integer)
    # Can be redeem, activity, referral, bonus, ...
    field(:source, :string)

    timestamps(type: :utc_datetime)

    belongs_to(:user, User)
    belongs_to(:activity, ActivityAccumulator)
  end

  def activity_points_changeset(point, %ActivityAccumulator{
        id: activity_id,
        type: activity_type,
        distance: distance
      },
      %User{id: user_id, daily_points_limit: daily_points_limit, todays_points: todays_points}) do
    point
    |> cast(%{}, [])
    |> put_change(:activity_id, activity_id)
    |> put_change(:user_id, user_id)
    |> put_change(:source, "activity")
    |> validate_activity_type(@allowed_activity_types, activity_type)
    |> add_balance_from_distance(distance, daily_points_limit, todays_points)
    |> validate_required(@required_attributes)
  end

  def changeset(point, attrs \\ %{}) do
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

  defp add_balance_from_distance(changeset, distance, daily_points_limit, todays_points) when not is_nil(distance) do
    max_balance = daily_points_limit * @points_per_km
    remaining_balance_today = max_balance - todays_points
    points = distance |> Decimal.round(0, :floor) |> Decimal.to_integer() |> Kernel.*(@points_per_km)

    cond do
      remaining_balance_today == 0  ->
        add_error(changeset, :id, "User reached max points for today")

      points < 10 or points == 0 ->
        add_error(changeset, :id, "Activity's distance is less than 1KM")

      points >= remaining_balance_today ->
        put_change(changeset, :balance, remaining_balance_today)

      points < remaining_balance_today ->
        put_change(changeset, :balance, points)
    end
  end

  defp add_balance_from_distance(changeset, _, _, _), do: changeset

  def get_points_per_km(), do: @points_per_km
end
