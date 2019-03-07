defmodule OmegaBravera.Offers.OfferChallengeActivity do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Offers.OfferChallenge}


  schema "offer_challenge_activities" do
    field :admin_id, :integer
    field :average_speed, :decimal
    field :calories, :decimal
    field :distance, :decimal
    field :elapsed_time, :integer
    field :manual, :boolean, default: false
    field :moving_time, :integer
    field :name, :string
    field :start_date, :utc_datetime
    field :strava_id, :integer
    field :type, :string

    timestamps(type: :utc_datetime)

    # associations
    belongs_to(:user, User)
    belongs_to(:offer_challenge, OfferChallenge)
  end

  @meters_per_km 1000
  @km_per_hour Decimal.from_float(3.6)
  @required_attributes [
    :distance,
    :start_date,
    :type,
    :user_id,
    :offer_challenge_id
  ]

  @required_attributes_for_admin [
    :start_date,
    :distance,
    :average_speed,
    :calories,
    :moving_time,
    :type,
    :user_id,
    :offer_challenge_id
  ]

  @allowed_attributes [
    :name,
    :manual,
    :average_speed,
    :calories,
    :moving_time,
    :elapsed_time
    | @required_attributes
  ]
  @activity_type [
    "Run",
    "Cycle",
    "Walk",
    "Hike"
  ]

  def create_changeset(%Strava.Activity{} = strava_activity, %OfferChallenge{} = offer_challenge, user) do
    %__MODULE__{}
    |> cast(strava_attributes(strava_activity), @allowed_attributes)
    |> change(%{
      strava_id: strava_activity.id,
      user_id: user.id,
      offer_challenge_id: offer_challenge.id,
      distance: to_km(strava_activity.distance),
      average_speed: to_km_per_hour(strava_activity.average_speed),
      moving_time: strava_activity.moving_time,
      elapsed_time: strava_activity.elapsed_time,
      calories: strava_activity.calories
    })
    |> validate_required(@required_attributes)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:offer_challenge_id)
    |> unique_constraint(:strava_id)
    |> unique_constraint(:offer_challenge_id)
    |> unique_constraint(:strava_id_challenge_id)
    |> validate_inclusion(:type, @activity_type)
  end

  def create_activity_by_admin_changeset(
        %Strava.Activity{} = strava_activity,
        %OfferChallenge{} = offer_challenge,
        user,
        admin_user_id
      ) do
    %__MODULE__{}
    |> cast(strava_attributes(strava_activity), @required_attributes_for_admin)
    |> change(%{
      strava_id: strava_activity.id,
      user_id: user.id,
      offer_challenge_id: offer_challenge.id,
      distance: strava_activity.distance,
      average_speed: strava_activity.average_speed,
      moving_time: strava_activity.moving_time,
      calories: strava_activity.calories,
      admin_id: admin_user_id
    })
    |> validate_required(@required_attributes_for_admin)
    |> check_constraint(:admin_id, name: :strava_id_or_admin_id_required)
    |> check_constraint(:strava_id, name: :strava_id_or_admin_id_required)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:offer_challenge_id)
    |> unique_constraint(:offer_challenge_id)
    |> validate_inclusion(:type, @activity_type)
  end

  defp to_km(nil), do: nil

  defp to_km(meters) when is_float(meters),
    do: Decimal.div(Decimal.from_float(meters), @meters_per_km)

  defp to_km(meters),
    do: Decimal.div(Decimal.new(meters), @meters_per_km)

  defp to_km_per_hour(nil), do: nil

  defp to_km_per_hour(meters_per_second) when is_float(meters_per_second),
    do: Decimal.mult(Decimal.from_float(meters_per_second), @km_per_hour)

  defp to_km_per_hour(meters_per_second),
    do: Decimal.mult(Decimal.new(meters_per_second), @km_per_hour)

  defp strava_attributes(%Strava.Activity{} = strava_activity),
    do: Map.take(strava_activity, @allowed_attributes)
end
