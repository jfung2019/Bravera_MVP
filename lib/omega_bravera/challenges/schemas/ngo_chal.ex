defmodule OmegaBravera.Challenges.NGOChal do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{
    Accounts.User,
    Fundraisers.NGO,
    Money.Donation,
    Challenges.Team,
    Challenges.Activity
  }

  @per_km "PER_KM"
  @per_milestone "PER_MILESTONE"

  @available_challenge_types [
    [key: "Per Goal", value: @per_milestone],
    [key: "Per KM", value: @per_km]
  ]

  schema "ngo_chals" do
    field(:activity_type, :string)
    field(:distance_target, :integer, default: 100)
    field(:distance_covered, :decimal, default: 0, virtual: true)
    field(:duration, :integer)
    field(:milestones, :integer, default: 4)
    field(:money_target, :decimal, default: 2000)
    field(:default_currency, :string, default: "hkd")
    field(:slug, :string)
    field(:start_date, :utc_datetime)
    field(:end_date, :utc_datetime)
    field(:status, :string, default: "active")
    field(:last_activity_received, :utc_datetime)
    field(:type, :string)

    field(:participant_notified_of_inactivity, :boolean, default: false)
    field(:donor_notified_of_inactivity, :boolean, default: false)
    field(:self_donated, :boolean, default: false)

    belongs_to(:user, User)
    belongs_to(:ngo, NGO)
    belongs_to(:team, Team)
    has_many(:donations, Donation)
    has_many(:activities, Activity, foreign_key: :challenge_id)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :activity_type,
    :money_target,
    :distance_target,
    :distance_covered,
    :slug,
    :status,
    :duration,
    :milestones,
    :default_currency,
    :user_id,
    :ngo_id,
    :self_donated,
    :type,
    :start_date
  ]

  @required_attributes [
    :activity_type,
    :money_target,
    :distance_target,
    :status,
    :duration,
    :user_id,
    :ngo_id,
    :slug,
    :type
  ]

  @activity_types [
    "Run",
    "Cycle",
    "Walk",
    "Hike"
  ]

  @available_distances %{
    50 => %{"1" => 0, "2" => 15, "3" => 25, "4" => 50},
    75 => %{"1" => 0, "2" => 25, "3" => 45, "4" => 75},
    100 => %{"1" => 0, "2" => 35, "3" => 65, "4" => 100},
    150 => %{"1" => 0, "2" => 50, "3" => 100, "4" => 150},
    250 => %{"1" => 0, "2" => 75, "3" => 150, "4" => 250},
    300 => %{"1" => 0, "2" => 75, "3" => 150, "4" => 300},
    400 => %{"1" => 0, "2" => 100, "3" => 250, "4" => 400},
    500 => %{"1" => 0, "2" => 150, "3" => 350, "4" => 500}
  }

  @doc false
  def changeset(ngo_chal, attrs) do
    ngo_chal
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_number(:distance_target, greater_than: 0)
    |> validate_inclusion(:distance_target, distances_available())
    |> validate_number(:money_target, greater_than: 0)
    |> validate_inclusion(:activity_type, @activity_types)
  end

  def create_changeset(ngo_chal, ngo, attrs) do
    ngo_chal
    |> changeset(attrs)
    |> add_start_and_end_dates(ngo, attrs)
    |> add_status(ngo)
    |> validate_required([:start_date, :end_date])
  end

  defp add_status(%Ecto.Changeset{} = changeset, %NGO{} = ngo) do
    status =
      case ngo.open_registration == false and ngo.launch_date >= Timex.now() do
        true -> "pre_registration"
        _ -> "active"
      end

    changeset |> change(status: status)
  end

  def activity_completed_changeset(%__MODULE__{} = challenge, %{distance: distance}) do
    challenge
    |> change(distance_covered: Decimal.add(challenge.distance_covered, distance))
    |> change(%{
      last_activity_received: Timex.now(),
      participant_notified_of_inactivity: false,
      donor_notified_of_inactivity: false
    })
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
    |> Enum.map(&"#{&1} Km")
    |> Enum.join(", ")
  end

  def milestones_distances(%__MODULE__{distance_target: target}) do
    case target do
      50 -> %{"1" => 0, "2" => 15, "3" => 25, "4" => 50}
      75 -> %{"1" => 0, "2" => 25, "3" => 45, "4" => 75}
      100 -> %{"1" => 0, "2" => 35, "3" => 65, "4" => 100}
      150 -> %{"1" => 0, "2" => 50, "3" => 100, "4" => 150}
      250 -> %{"1" => 0, "2" => 75, "3" => 150, "4" => 250}
      300 -> %{"1" => 0, "2" => 75, "3" => 150, "4" => 300}
      400 -> %{"1" => 0, "2" => 100, "3" => 250, "4" => 400}
      500 -> %{"1" => 0, "2" => 150, "3" => 350, "4" => 500}
    end
  end

  def activity_types, do: @activity_types

  def distances_available, do: Map.keys(@available_distances)

  defp add_start_and_end_dates(
         %Ecto.Changeset{} = changeset,
         %NGO{} = ngo,
         %{"duration" => duration_str} = attrs
       )
       when is_binary(duration_str) do
    duration =
      case Integer.parse(duration_str) do
        {duration, _} -> duration
        _ -> nil
      end

    add_start_and_end_dates(changeset, ngo, Map.put(attrs, "duration", duration))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, %NGO{} = ngo, %{
         "duration" => duration
       })
       when is_number(duration) do
    {start_date, end_date} =
      case ngo.open_registration == false and ngo.launch_date >= Timex.now() do
        true -> {ngo.launch_date, Timex.shift(ngo.launch_date, days: duration)}
        _ -> {Timex.now(), Timex.shift(Timex.now(), days: duration)}
      end

    changeset
    |> change(start_date: start_date)
    |> change(end_date: end_date)
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, _, _), do: changeset

  defp update_challenge_status(%Ecto.Changeset{} = changeset, challenge) do
    case Decimal.cmp(changeset.changes[:distance_covered], challenge.distance_target) do
      :lt -> changeset
      _ -> change(changeset, status: "complete")
    end
  end

  def challenge_type_options, do: @available_challenge_types

  defimpl Phoenix.Param, for: OmegaBravera.Challenges.NGOChal do
    def to_param(%{slug: slug}), do: slug
  end
end
