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

    # associations
    belongs_to(:user, User)
    belongs_to(:challenge, NGOChal)

    timestamps(type: :utc_datetime)
  end

  @meters_per_km 1000
  @required_attributes [:distance, :start_date, :type, :user_id, :challenge_id]
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
      distance: to_km(strava_activity.distance)
    })
    |> validate_required(@required_attributes)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:challenge_id)
    |> unique_constraint(:strava_id)
    |> unique_constraint(:challenge_id)
    |> validate_inclusion(:type, @activity_type)
  end

  defp to_km(meters) do
    Decimal.div(Decimal.new(meters), @meters_per_km)
  end

  defp strava_attributes(%Strava.Activity{} = strava_activity),
    do: Map.take(strava_activity, @allowed_attributes)
end
