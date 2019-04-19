defmodule OmegaBravera.Offers.OfferRedeem do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.{Offer, OfferChallenge, OfferReward, OfferVendor}
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Repo

  schema "offer_redeems" do
    field :team_id, :integer

    belongs_to(:offer_reward, OfferReward)
    belongs_to(:offer_challenge, OfferChallenge)
    belongs_to(:offer, Offer)
    belongs_to(:user, User)
    belongs_to(:vendor, OfferVendor)

    timestamps(type: :utc_datetime)
  end

  @allowed_atributes [:offer_reward_id, :vendor_id]
  @required_attributes [:offer_reward_id]

  @doc false
  def changeset(%__MODULE__{} = offer_redeems, attrs \\ %{}) do
    offer_redeems
    |> cast(attrs, @allowed_atributes)
    |> validate_required(@required_attributes)
  end

  def create_changeset(offer_redeems, offer_challenge, vendor, attrs \\ %{})

  def create_changeset(_, _, vendor, attrs) when is_nil(vendor) == true do
    %__MODULE__{}
    |> changeset(attrs)
    |> add_error(:vendor_id, "Your Vendor ID seems to be incorrect.")
  end

  def create_changeset(
        %__MODULE__{} = offer_redeems,
        %OfferChallenge{offer: offer, user: user} = offer_challenge,
        %OfferVendor{} = vendor,
        attrs
      ) do
    changeset(offer_redeems, attrs)
    |> put_change(:user_id, user.id)
    |> put_change(:vendor_id, vendor.id)
    |> put_change(:offer_challenge_id, offer_challenge.id)
    |> put_change(:offer_id, offer.id)
    |> validate_required([:vendor_id])
    |> add_team_id(offer_challenge)
    |> is_previously_redeemed(offer_challenge)
  end

  defp add_team_id(%Ecto.Changeset{} = changeset, %OfferChallenge{has_team: false}), do: changeset

  defp add_team_id(%Ecto.Changeset{} = changeset, %OfferChallenge{has_team: true} = offer_challenge) do
    offer_challenge = Repo.preload(offer_challenge, [:team])

    put_change(changeset, :team_id, offer_challenge.team.id)
  end

  defp is_previously_redeemed(%Ecto.Changeset{} = changeset, %OfferChallenge{has_team: false} = offer_challenge) do
    offer_challenge = Repo.preload(offer_challenge, [:offer_redeems])

    if !Enum.empty?(offer_challenge.offer_redeems) do
      add_error(changeset, :offer_challenge_id, "Challenge previously redeemed award.")
    else
      changeset
    end
  end

  defp is_previously_redeemed(%Ecto.Changeset{} = changeset, %OfferChallenge{has_team: true} = offer_challenge) do
    offer_challenge = Repo.preload(offer_challenge, [:offer_redeems, team: [:users]])

    # Team members + Challenge Owner
    team_count = length(offer_challenge.team.users) + 1

    cond do
      team_count == length(offer_challenge.offer_redeems) or length(offer_challenge.offer_redeems) > team_count ->
        add_error(changeset, :offer_challenge_id, "Could not redeem reward. All challenge members received an award previously.")

        team_count > length(offer_challenge.offer_redeems) ->
        changeset

      true ->
        changeset
    end
  end
end
