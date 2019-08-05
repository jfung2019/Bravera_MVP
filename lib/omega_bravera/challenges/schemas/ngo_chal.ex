defmodule OmegaBravera.Challenges.NGOChal do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.{
    Accounts.User,
    Fundraisers.NGO,
    Money.Donation,
    Challenges.Team,
    Challenges.NgoChallengeActivitiesM2m
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
    has_many(:activities, NgoChallengeActivitiesM2m, foreign_key: :challenge_id)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :activity_type,
    :money_target,
    :distance_target,
    :distance_covered,
    :status,
    :duration,
    :milestones,
    :default_currency,
    :user_id,
    :ngo_id,
    :self_donated,
    :type,
    :has_team,
    :start_date,
    :slug
  ]

  @required_attributes [
    :activity_type,
    :money_target,
    :distance_target,
    :status,
    :duration,
    :user_id,
    :ngo_id,
    :type
  ]

  @doc false
  def changeset(ngo_chal, user, attrs) do
    ngo_chal
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> generate_slug(user)
    |> validate_number(:distance_target, greater_than: 0)
    |> validate_inclusion(:distance_target, distance_options())
    |> validate_number(:money_target, greater_than: 0)
    |> validate_inclusion(:activity_type, activity_options())
    |> validate_inclusion(:default_currency, currency_options())
    |> validate_inclusion(:duration, duration_options())
    |> validate_inclusion(:type, challenge_type_options())
    |> validate_required(:slug)
    |> unique_constraint(:slug,
      name: :ngo_chals_slug_unique_index,
      message: "Challenge's slug must be unique."
    )
  end

  def create_changeset(ngo_chal, ngo, user, attrs) do
    ngo_chal
    |> changeset(user, attrs)
    |> add_start_and_end_dates(ngo, attrs)
    |> add_status(ngo)
    |> add_last_activity_received(ngo)
    |> validate_required([:start_date, :end_date])
  end

  def create_with_team_changeset(ngo_chal, ngo, user, attrs) do
    ngo_chal
    |> create_changeset(ngo, user, attrs)
    |> cast_assoc(:team, with: &Team.changeset/2, required: true)
  end

  def update_changeset(ngo_chal, user, attrs) do
    ngo_chal
    |> changeset(user, attrs)
    |> update_end_date(ngo_chal)
  end

  def generate_slug(%Ecto.Changeset{} = changeset, %User{firstname: firstname}) do
    slug = get_field(changeset, :slug)

    cond do
      not is_nil(slug) ->
        changeset

      is_nil(slug) and not is_nil(firstname) ->
        change(changeset, slug: "#{Slug.slugify(firstname)}-#{gen_unique_string()}")

      true ->
        changeset
    end
  end

  defp gen_unique_string(length \\ 4),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)

  def update_end_date(%Ecto.Changeset{} = changeset, %__MODULE__{
        end_date: end_date,
        duration: old_duration
      }) do
    new_duration = get_change(changeset, :duration)

    cond do
      is_nil(new_duration) ->
        changeset

      new_duration == old_duration ->
        changeset

      new_duration > old_duration ->
        change(changeset,
          end_date: end_date_without_seconds(end_date, new_duration - old_duration)
        )

      new_duration < old_duration ->
        change(changeset,
          end_date: end_date_without_seconds(end_date, -(old_duration - new_duration))
        )
    end
  end

  defp end_date_without_seconds(%DateTime{} = start_date, new_duration),
    do: Timex.shift(start_date, days: new_duration) |> DateTime.truncate(:second)

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
      last_activity_received: DateTime.truncate(Timex.now(), :second),
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
    |> change(last_activity_received: DateTime.truncate(last_activity_received, :second))
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
      cond do
        ngo.open_registration == false and Timex.after?(ngo.utc_launch_date, Timex.now()) ->
          {ngo.utc_launch_date, Timex.shift(ngo.utc_launch_date, days: duration)}

        true ->
          {Timex.now(), Timex.shift(Timex.now(), days: duration)}
      end

    changeset
    |> change(start_date: DateTime.truncate(start_date, :second))
    |> change(end_date: DateTime.truncate(end_date, :second))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, _, _), do: changeset

  defp update_challenge_status(%Ecto.Changeset{} = changeset, challenge) do
    distance_covered = get_change(changeset, :distance_covered, Decimal.new(0))

    case Decimal.cmp(distance_covered, challenge.distance_target) do
      :lt -> changeset
      _ -> change(changeset, status: "complete")
    end
  end

  def milestones_distances(%__MODULE__{distance_target: target}),
    do: milestone_distances(target)
end
