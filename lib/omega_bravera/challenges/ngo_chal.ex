defmodule OmegaBravera.Challenges.NGOChal do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Fundraisers.NGO
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Challenges.Team

  schema "ngo_chals" do
    field :activity, :string
    field :distance_target, :integer, default: 100
    field :distance_covered, :decimal, default: 0
    field :duration, :integer
    field :milestones, :integer, default: 4
    field :money_target, :decimal, default: 2000
    field :default_currency, :string, default: "hkd"
    field :slug, :string
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    field :status, :string, default: "active"
    field :total_pledged, :decimal, default: 0
    field :total_secured, :decimal, default: 0
    field :last_activity_received, :utc_datetime
    field :participant_notified_of_inactivity, :boolean, default: false
    field :donor_notified_of_inactivity, :boolean, default: false
    belongs_to :user, User
    belongs_to :ngo, NGO
    belongs_to :team, Team
    has_many :donations, Donation

    timestamps()
  end

  @allowed_attributes [
    :activity, :money_target, :distance_target, :distance_covered, :slug,
    :status, :duration, :milestones, :total_pledged, :total_secured, :default_currency,
    :user_id, :ngo_id
  ]

  @required_attributes [
    :activity, :money_target, :distance_target,
    :status, :duration, :user_id, :ngo_id, :slug
  ]

  @meters_per_km 1000

  @doc false
  def changeset(ngo_chal, attrs) do
    ngo_chal
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_number(:distance_target, greater_than: 0)
    |> validate_number(:money_target, greater_than: 0)
  end

  def create_changeset(ngo_chal, attrs) do
    ngo_chal
    |> changeset(attrs)
    |> add_start_and_end_dates(attrs)
    |> validate_required([:start_date, :end_date])
  end

  def activity_completed_changeset(%__MODULE__{} = challenge, %Strava.Activity{distance: distance}) do
    challenge
    |> update_covered_distance(distance)
    |> change(%{last_activity_received: Timex.now, participant_notified_of_inactivity: false, donor_notified_of_inactivity: false})
    |> update_challenge_status(challenge)
  end

  def participant_inactivity_notification_changeset(%__MODULE__{} = challenge) do
    change(challenge, %{participant_notified_of_inactivity: true})
  end

  def donor_inactivity_notification_changeset(%__MODULE__{} = challenge) do
    change(challenge, %{donor_notified_of_inactivity: true})
  end

  def milestones_string(%__MODULE__{} = challenge) do
    challenge
    |> milestones_distances()
    |> Map.take(["2", "3", "4"])
    |> Map.values()
    |> Enum.map(&("#{&1} Km"))
    |> Enum.join(", ")
  end

  def milestones_distances(%__MODULE__{} = challenge) do
    case challenge.distance_target do
      50 -> %{"1" => 0, "2" => 15, "3" => 25, "4" => 50}
      75 -> %{"1" => 0, "2" => 25, "3" => 45, "4" => 75}
      150 -> %{"1" => 0, "2" => 50, "3" => 100, "4" => 150}
      250 -> %{"1" => 0, "2" => 75, "3" => 150, "4" => 250}
    end
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, %{"duration" => duration_str} = attrs) when is_binary(duration_str) do
    duration = case Integer.parse(duration_str) do
                 {duration, _} -> duration
                 _ -> nil
               end
    add_start_and_end_dates(changeset, Map.put(attrs, "duration", duration))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, %{"duration" => duration}) when is_number(duration) do
    start_date = Timex.now
    end_date = Timex.shift(start_date, days: duration)

    changeset
    |> change(start_date: start_date)
    |> change(end_date: end_date)
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, _) do
    changeset
  end

  defp update_challenge_status(%Ecto.Changeset{} = changeset, challenge) do
    case Decimal.cmp(changeset.changes[:distance_covered], challenge.distance_target) do
      :lt -> changeset
      _ -> change(changeset, status: "complete")
    end
  end

  defp update_covered_distance(%__MODULE__{} = challenge, distance) do
    challenge
    |> change(distance_covered: Decimal.add(challenge.distance_covered, strava_distance_in_km(distance)))
  end

  defp strava_distance_in_km(distance), do: Decimal.div(distance, @meters_per_km)
end
