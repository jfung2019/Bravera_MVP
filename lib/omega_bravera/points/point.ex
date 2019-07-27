defmodule OmegaBravera.Points.Point do
  @moduledoc """
  Point Schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Activity.ActivityAccumulator

  @allowed_attributes [:activity_id, :user_id, :balance, :source]
  @required_attributes [:user_id, :balance, :source]

  schema "points" do
    # Can be in -ve or +ve.
    field(:balance, :integer)
    # Can be redeem, activity, referral, bonus, ...
    field(:source, :string)

    belongs_to(:user, User)
    belongs_to(:activity, ActivityAccumulator)
  end

  def activity_points_changeset(point, %ActivityAccumulator{id: activity_id, user_id: user_id, distance: distance}) do
    point
    |> cast(%{}, [])
    |> put_change(:activity_id, activity_id)
    |> put_change(:user_id, user_id)
    |> put_change(:source, "activity")
    |> add_balance_from_distance(distance)
    |> validate_required(@required_attributes)
  end

  def changeset(point, attrs \\ %{}) do
    point
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
  end

  defp add_balance_from_distance(changeset, distance) when not is_nil(distance) do
    balance = distance |> Decimal.round() |> Decimal.to_integer()

    cond do
      balance < 1 or balance == 0 or balance < 0 ->
        add_error(changeset, :id, "Activity's distance is less than 1KM")

      balance == 1 ->
        put_change(changeset, :balance, 10)

      balance > 1 ->

        put_change(changeset, :balance, balance * 10)
    end
  end
end
