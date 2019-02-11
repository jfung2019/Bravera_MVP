defmodule OmegaBravera.Challenges.NGOChal do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.{
    Accounts.User,
    Fundraisers.NGO,
    Money.Donation,
    Challenges.Team,
    Challenges.Activity
  }

  @derive {Phoenix.Param, key: :slug}
  schema "ngo_chals" do
    field(:activity_type, :string)
    field(:distance_target, :integer, default: 100)
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

    field(:has_team, :boolean, default: false)
    field(:participant_notified_of_inactivity, :boolean, default: false)
    field(:donor_notified_of_inactivity, :boolean, default: false)
    field(:self_donated, :boolean, default: false)

    field(:distance_covered, :decimal, default: 0, virtual: true)

    belongs_to(:user, User)
    belongs_to(:ngo, NGO)
    has_one(:team, Team, foreign_key: :challenge_id)
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
    :has_team,
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

  @doc false
  def changeset(ngo_chal, attrs) do
    ngo_chal
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> validate_number(:distance_target, greater_than: 0)
    |> validate_inclusion(:distance_target, distance_options())
    |> validate_number(:money_target, greater_than: 0)
    |> validate_inclusion(:activity_type, activity_options())
    |> validate_inclusion(:default_currency, currency_options())
    |> validate_inclusion(:duration, duration_options())
    |> validate_inclusion(:type, challenge_type_options())
    |> unique_constraint(:slug,
      name: :ngo_chals_slug_unique_index,
      message: "Challenge's slug must be unique."
    )
  end

  def create_changeset(ngo_chal, ngo, attrs) do
    ngo_chal
    |> changeset(attrs)
    |> add_start_and_end_dates(ngo, attrs)
    |> add_status(ngo)
    |> add_last_activity_received(ngo)
    |> validate_required([:start_date, :end_date])
  end

  def create_with_team_changeset(ngo_chal, ngo, attrs) do
    ngo_chal
    |> create_changeset(ngo, attrs)
    |> cast_assoc(:team, with: &Team.changeset/2, required: true)
  end

  defp add_status(%Ecto.Changeset{} = changeset, %NGO{
         open_registration: open_registration,
         utc_launch_date: utc_launch_date
       }) do
    status =
      case open_registration == false and Timex.after?(utc_launch_date, Timex.now()) do
        true -> "pre_registration"
        _ -> "active"
      end

    changeset
    |> change(status: status)
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

  defp add_last_activity_received(%Ecto.Changeset{} = changeset, %NGO{launch_date: launch_date}) do
    status = get_field(changeset, :status)

    last_activity_received =
      case status do
        "pre_registration" -> launch_date
        _ -> Timex.now()
      end

    changeset
    |> change(last_activity_received: last_activity_received)
  end

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
      case ngo.open_registration == false and Timex.after?(ngo.utc_launch_date, Timex.now()) do
        true -> {ngo.utc_launch_date, Timex.shift(ngo.utc_launch_date, days: duration)}
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

  def milestones_distances(%__MODULE__{distance_target: target}),
    do: milestone_distances(target)
end
