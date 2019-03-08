defmodule OmegaBravera.Offers.OfferChallenge do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.{Offers.Offer, Accounts.User, Offers.OfferChallengeActivity}

  schema "offer_challenges" do
    field(:activity_type, :string)
    field(:default_currency, :string, default: "hkd")
    field(:distance_target, :integer, default: 100)
    field(:duration, :integer)
    field(:milestones, :integer, default: 4)
    field(:end_date, :utc_datetime)
    field(:has_team, :boolean, default: false)
    field(:last_activity_received, :utc_datetime)
    field(:participant_notified_of_inactivity, :boolean, default: false)
    field(:slug, :string)
    field(:start_date, :utc_datetime)
    field(:status, :string, default: "active")
    field(:type, :string)

    field(:distance_covered, :decimal, default: 0, virtual: true)

    belongs_to(:user, User)
    belongs_to(:offer, Offer)
    has_many(:offer_challenge_activities, OfferChallengeActivity)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :user_id,
    :slug,
  ]

  @required_attributes [
    :user_id,
    :slug,
  ]

  @doc false
  def changeset(offer_challenge, attrs) do
    offer_challenge
    |> cast(attrs, @allowed_attributes)
    |> validate_required(@required_attributes)
    |> unique_constraint(:user_id_offer_id, name: :one_offer_per_user_index, message: "You cannot join an offer more then once.")
    |> unique_constraint(:slug)
  end

  def create_changeset(offer_challenge, offer, attrs) do
    offer_challenge
    |> changeset(attrs)
    |> change(%{
      offer_id: offer.id,
      default_currency: offer.currency,
      type: hd(offer.offer_challenge_types),
      activity_type: hd(offer.activities),
      distance_target: hd(offer.distances),
      duration: hd(offer.durations)
    })
    |> validate_number(:distance_target, greater_than: 0)
    |> validate_inclusion(:distance_target, distance_options())
    |> validate_inclusion(:activity_type, activity_options())
    |> validate_inclusion(:default_currency, currency_options())
    |> validate_inclusion(:duration, duration_options())
    |> validate_inclusion(:type, challenge_type_options())
    |> add_start_and_end_dates(offer)
    |> add_status(offer)
    |> add_last_activity_received(offer)
    |> validate_required([:start_date, :end_date])
  end

  defp add_status(%Ecto.Changeset{} = changeset, %Offer{
         open_registration: open_registration,
         launch_date: launch_date
       }) do
    status =
      case open_registration == false and Timex.after?(launch_date, Timex.now()) do
        true -> "pre_registration"
        _ -> "active"
      end

    changeset
    |> change(status: status)
  end

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

  defp add_last_activity_received(%Ecto.Changeset{} = changeset, %Offer{launch_date: launch_date}) do
    status = get_field(changeset, :status)

    last_activity_received =
      case status do
        "pre_registration" -> launch_date
        _ -> Timex.now()
      end

    changeset
    |> change(last_activity_received: DateTime.truncate(last_activity_received, :second))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, %Offer{} = offer) do
    add_start_and_end_dates(changeset, offer, get_field(changeset, :duration))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, %Offer{} = offer, duration) when is_number(duration) do
    {start_date, end_date} =
      cond do
        offer.open_registration == false and Timex.after?(offer.launch_date, Timex.now()) ->
          {offer.launch_date, Timex.shift(offer.launch_date, days: duration)}

        true ->
          {Timex.now(), Timex.shift(Timex.now(), days: duration)}
      end

    changeset
    |> change(start_date: DateTime.truncate(start_date, :second))
    |> change(end_date: DateTime.truncate(end_date, :second))
  end

  defp add_start_and_end_dates(%Ecto.Changeset{} = changeset, _, _), do: changeset

  defp update_challenge_status(%Ecto.Changeset{} = changeset, challenge) do
    case Decimal.cmp(changeset.changes[:distance_covered], challenge.distance_target) do
      :lt -> changeset
      _ -> change(changeset, status: "complete")
    end
  end

  def milestones_string(%__MODULE__{} = challenge) do
    challenge
    |> milestones_distances()
    |> Map.take(["2", "3", "4"])
    |> Map.values()
    |> Enum.map(&"#{&1} Km")
    |> Enum.join(", ")
  end

  def milestones_distances(%__MODULE__{distance_target: target}),
    do: milestone_distances(target)
end
