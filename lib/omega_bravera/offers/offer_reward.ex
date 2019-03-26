defmodule OmegaBravera.Offers.OfferReward do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.Offer

  schema "offer_rewards" do
    field(:name, :string)
    field(:value, :integer)

    belongs_to(:offer, Offer)

    timestamps(type: :utc_datetime)
  end

  @allowed_atributes [:name, :value, :offer_id]
  @required_attributes [:name, :value, :offer_id]

  @doc false
  def changeset(offer_reward, attrs) do
    offer_reward
    |> cast(attrs, @allowed_atributes)
    |> validate_required(@required_attributes)
  end
end
