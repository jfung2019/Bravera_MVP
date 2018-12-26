defmodule OmegaBravera.Challenges.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Challenges.NGOChal}

  schema "activities" do
    field(:strava_id, :integer)
    field(:name, :string)
    field(:distance, :decimal, default: 0)
    field(:start_date, :utc_datetime)
    field(:manual, :boolean)
    field(:type, :string)
    field(:average_speed, :decimal)
    field(:moving_time, :integer)
    field(:elapsed_time, :integer)
    field(:calories, :decimal)

    # associations
    belongs_to(:user, User)
    belongs_to(:challenge, NGOChal)

    timestamps(type: :utc_datetime)
  end

  @meters_per_km 1000
  @km_per_hour Decimal.new(3.6)
  @required_attributes [
    :average_speed,
    :moving_time,
    :elapsed_time,
    :distance,
    :start_date,
    :type,
    :user_id,
    :challenge_id,
    :calories
  ]
  @allowed_attributes [:name, :manual | @required_attributes]
  @activity_type [
    "Run",
    "Cycle",
    "Walk",
    "Hike"
  ]

  def create_changeset(%Strava.Activity{} = strava_activity, %NGOChal{} = challenge) do
    %__MODULE__{}
    |> cast(strava_attributes(strava_activity), @allowed_attributes)
    |> change(%{
      strava_id: strava_activity.id,
      user_id: challenge.user_id,
      challenge_id: challenge.id,
      distance: to_km(strava_activity.distance),
      average_speed: to_km_per_hour(strava_activity.average_speed),
      moving_time: strava_activity.moving_time,
      elapsed_time: strava_activity.elapsed_time,
      calories: strava_activity.calories
    })
    |> validate_required(@required_attributes)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:challenge_id)
    |> unique_constraint(:strava_id)
    |> unique_constraint(:challenge_id)
    |> validate_inclusion(:type, @activity_type)
  end

  defp to_km(nil), do: nil

  defp to_km(meters),
    do: Decimal.div(Decimal.new(meters), @meters_per_km)

  defp to_km_per_hour(nil), do: nil

  defp to_km_per_hour(meters_per_second),
    do: Decimal.mult(Decimal.new(meters_per_second), @km_per_hour)

  defp strava_attributes(%Strava.Activity{} = strava_activity),
    do: Map.take(strava_activity, @allowed_attributes)
end
