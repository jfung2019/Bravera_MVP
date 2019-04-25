defmodule OmegaBravera.Offers.OfferChallenge do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.Fundraisers.NgoOptions

  alias OmegaBravera.{
    Offers.Offer,
    Accounts.User,
    Offers.OfferChallengeActivity,
    Offers.OfferRedeem,
    Offers.OfferChallengeTeam,
    Repo
  }

  @derive {Phoenix.Param, key: :slug}
  schema "offer_challenges" do
    field(:activity_type, :string)
    field(:default_currency, :string, default: "hkd")
    field(:distance_target, :integer, default: 100)
    field(:milestones, :integer, default: 4)
    field(:end_date, :utc_datetime)
    field(:has_team, :boolean, default: false)
    field(:last_activity_received, :utc_datetime)
    field(:participant_notified_of_inactivity, :boolean, default: false)
    field(:slug, :string)
    field(:start_date, :utc_datetime)
    field(:status, :string, default: "active")
    field(:type, :string)
    field(:redeemed, :integer, default: 0)
    field(:redeem_token, :string)

    field(:distance_covered, :decimal, default: Decimal.new(0), virtual: true)

    belongs_to(:user, User)
    belongs_to(:offer, Offer)
    has_many(:offer_redeems, OfferRedeem, foreign_key: :offer_challenge_id)
    has_one(:team, OfferChallengeTeam, foreign_key: :offer_challenge_id)

    has_many(:offer_challenge_activities, OfferChallengeActivity, foreign_key: :offer_challenge_id)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :start_date,
    :end_date,
    :activity_type,
    :distance_target,
    :status,
    :default_currency,
    :type
  ]

  @doc false
  def changeset(offer_challenge, attrs \\ %{}) do
    offer_challenge
    |> cast(attrs, @allowed_attributes)
  end

  def create_changeset(offer_challenge, offer, user, attrs \\ %{team: %{}, offer_redeems: [%{}]}) do
    offer_challenge
    |> changeset(attrs)
    |> change(%{
      offer_id: offer.id,
      default_currency: offer.currency,
      type: hd(offer.offer_challenge_types),
      activity_type: hd(offer.activities),
      distance_target: hd(offer.distances)
    })
    |> validate_number(:distance_target, greater_than: 0)
    |> validate_inclusion(:distance_target, distance_options())
    |> validate_inclusion(:activity_type, activity_options())
    |> validate_inclusion(:default_currency, currency_options())
    |> validate_inclusion(:type, challenge_type_options())
    |> add_start_and_end_dates(offer)
    |> add_status(offer)
    |> generate_slug(user)
    |> put_change(:user_id, user.id)
    |> add_last_activity_received(offer)
    |> validate_required([:start_date, :end_date])
    |> validate_user_has_no_active_offer_challenges(user)
    |> validate_required(:slug)
    |> unique_constraint(:user_id_offer_id,
      name: :one_offer_per_user_index,
      message: "You cannot join an offer more then once."
    )
    |> unique_constraint(:slug)
    |> solo_or_team_challenge(offer, user)
    |> add_one_offer_redeem_assoc(offer, user)
  end

  def create_with_team_changeset(offer_challenge, offer, user, attrs) do
    offer_challenge
    |> create_changeset(offer, user, attrs)
    |> cast_assoc(:team, with: &OfferChallengeTeam.changeset(&1, offer, user, &2), required: true)
  end

  defp solo_or_team_challenge(
         %Ecto.Changeset{} = changeset,
         %Offer{additional_members: additional_members} = offer,
         %User{} = user
       ) do
    cond do
      additional_members > 0 ->
        changeset
        |> put_change(:has_team, true)
        |> cast_assoc(:team,
          with: &OfferChallengeTeam.changeset(&1, offer, user, &2),
          required: true
        )

      is_nil(additional_members) or additional_members == 0 ->
        changeset
    end
  end

  defp add_one_offer_redeem_assoc(
         %Ecto.Changeset{} = changeset,
         %Offer{} = offer,
         %User{} = user
       ) do
    changeset
    |> cast_assoc(:offer_redeems,
      with: &OfferRedeem.offer_challenge_assoc_changeset(&1, offer, user, &2),
      required: true
    )
  end

  defp generate_slug(%Ecto.Changeset{} = changeset, %User{firstname: firstname}) do
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
    if Timex.before?(Timex.now(), offer.end_date) and Timex.after?(Timex.now(), offer.start_date) do
      changeset
      |> change(start_date: DateTime.truncate(Timex.now(), :second))
      |> change(end_date: DateTime.truncate(offer.end_date, :second))
    else
      changeset
      |> add_error(:end_date, "Cannot create challenge. Either offer did not start yet or it is expired.")
    end
  end

  defp update_challenge_status(%Ecto.Changeset{} = changeset, challenge) do
    case Decimal.cmp(changeset.changes[:distance_covered], challenge.distance_target) do
      :lt -> changeset
      _ -> change(changeset, status: "complete")
    end
  end

  def validate_user_has_no_active_offer_challenges(%Ecto.Changeset{} = changeset, %User{} = user) do
    offer_id = get_field(changeset, :offer_id)
    user = Repo.preload(user, :offer_challenges)

    if Enum.find(user.offer_challenges, &(&1.offer_id == offer_id && &1.status == "active")) do
      changeset
      |> add_error(:offer_id, "Already participating in the challenge.")
    else
      changeset
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
