defmodule OmegaBravera.Offers.OfferRedeem do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.{Offer, OfferChallenge, OfferReward}
  alias OmegaBravera.Accounts.User


  schema "offer_redeems" do
    belongs_to(:offer_reward, OfferReward)
    belongs_to(:offer_challenge, OfferChallenge)
    belongs_to(:offer, Offer)
    belongs_to(:user, User)
    belongs_to(:vendor, User)

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

  def create_changeset(%__MODULE__{} = offer_redeems, %OfferChallenge{offer: offer, user: user} = offer_challenge, %User{} = vendor, attrs \\ %{}) do
    changeset =
      changeset(offer_redeems, attrs)
      |> put_change(:user_id, user.id)
      |> put_change(:vendor_id, vendor.id)
      |> put_change(:offer_challenge_id, offer_challenge.id)
      |> put_change(:offer_id, offer.id)
      |> validate_required([:vendor_id])

    if changeset.valid? do
      changeset
    else
      changeset
      |> put_change(:vendor_id, attrs["vendor_id"])
    end

  end
end
