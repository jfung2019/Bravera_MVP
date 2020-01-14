defmodule OmegaBravera.Activity.ActivityAccumulator do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Devices.Device
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Activity.StravaParser
  alias OmegaBravera.Offers.OfferChallengeActivitiesM2m
  alias OmegaBravera.Challenges.NgoChallengeActivitiesM2m

  @banned_sources ["garmin"]

  schema "activities_accumulator" do
    field(:strava_id, :integer)
    field(:name, :string)
    field(:distance, :decimal, default: 0)
    field(:start_date, :utc_datetime)
    field(:manual, :boolean)
    field(:type, :string)
    field(:average_speed, :decimal, default: 0)
    field(:moving_time, :integer, default: 0)
    field(:elapsed_time, :integer, default: 0)
    field(:calories, :decimal, default: 0)
    field(:activity_json, :map)
    field(:source, :string, default: nil)

    # App activities only.
    field(:end_date, :utc_datetime)
    # Only used for to record which admin created the activity
    field(:admin_id, :integer)

    belongs_to(:user, User)
    # App activities related
    belongs_to(:device, Device)

    many_to_many(:offer_activities, OfferChallengeActivitiesM2m,
      join_through: "offer_challenge_activities_m2m",
      join_keys: [activity_id: :id, offer_challenge_id: :id]
    )

    many_to_many(:ngo_activities, NgoChallengeActivitiesM2m,
      join_through: "ngo_challenge_activities_m2m",
      join_keys: [activity_id: :id, challenge_id: :id]
    )

    timestamps(type: :utc_datetime)
  end

  @meters_per_km 1000
  @km_per_hour Decimal.from_float(3.6)
  @required_attributes [
    :distance,
    :start_date,
    :type,
    :user_id
  ]

  @required_attributes_for_admin [
    :start_date,
    :distance,
    :average_speed,
    :calories,
    :moving_time,
    :type,
    :user_id
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

  def create_changeset(%Strava.DetailedActivity{} = strava_activity, user) do
    %__MODULE__{}
    |> cast(strava_attributes(strava_activity), @allowed_attributes)
    |> change(%{
      strava_id: strava_activity.id,
      user_id: user.id,
      distance: to_km(strava_activity.distance),
      average_speed: to_km_per_hour(strava_activity.average_speed),
      moving_time: strava_activity.moving_time,
      elapsed_time: strava_activity.elapsed_time,
      calories: strava_activity.calories,
      activity_json: StravaParser.strava_activity_to_map(strava_activity),
      source: "strava"
    })
    |> validate_required(@required_attributes)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:challenge_id)
    |> unique_constraint(:strava_id)
    |> unique_constraint(:challenge_id)
    |> unique_constraint(:strava_id_challenge_id)
  end

  def create_activity_by_admin_changeset(
        %Strava.DetailedActivity{} = strava_activity,
        user,
        admin_user_id
      ) do
    %__MODULE__{}
    |> cast(strava_attributes(strava_activity), @required_attributes_for_admin)
    |> change(%{
      strava_id: strava_activity.id,
      user_id: user.id,
      distance: strava_activity.distance,
      average_speed: strava_activity.average_speed,
      moving_time: strava_activity.moving_time,
      calories: strava_activity.calories,
      admin_id: admin_user_id,
      source: "admin"
    })
    |> validate_required(@required_attributes_for_admin)
    |> check_constraint(:admin_id, name: :strava_id_or_admin_id_or_device_id_required)
    |> check_constraint(:strava_id, name: :strava_id_or_admin_id_or_device_id_required)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:challenge_id)
  end

  def create_bravera_app_activity(
        activity_attrs,
        user_id,
        device_id,
        number_of_activities_at_time
      ) do
    %__MODULE__{}
    |> cast(activity_attrs, [:distance, :start_date, :end_date, :source, :type])
    |> put_change(:user_id, user_id)
    |> put_change(:device_id, device_id)
    |> verify_allowed_source()
    |> validate_required([:user_id, :device_id, :type])
    |> verify_not_duplicate(number_of_activities_at_time)
    |> check_constraint(:admin_id, name: :strava_id_or_admin_id_or_device_id_required)
    |> check_constraint(:strava_id, name: :strava_id_or_admin_id_or_device_id_required)
  end

  def verify_allowed_source(changeset) do
    source = get_field(changeset, :source)

    if not is_nil(source) do
      if !Enum.member?(@banned_sources, source) do
        put_change(changeset, :source, String.downcase(source))
      else
        add_error(changeset, :source, "#{source} is not allowed.")
      end
    else
      put_change(changeset, :source, "empty")
    end
  end

  def verify_not_duplicate(changeset, number_of_activities_at_time)
      when not is_nil(number_of_activities_at_time) and number_of_activities_at_time > 0,
      do: add_error(changeset, :id, "Duplicate activity")

  def verify_not_duplicate(changeset, _number_of_activities_at_time), do: changeset

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

  defp strava_attributes(%Strava.DetailedActivity{} = strava_activity),
    do: Map.take(strava_activity, @allowed_attributes)
end
