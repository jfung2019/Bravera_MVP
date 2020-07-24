defmodule OmegaBravera.Partners.OfferPartner do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "offer_partners" do
    belongs_to :offer, OmegaBravera.Offers.Offer
    belongs_to :partner, OmegaBravera.Partners.Partner

    timestamps()
  end

  @doc false
  def changeset(offer_partner, attrs) do
    offer_partner
    |> cast(attrs, [:offer_id, :partner_id])
    |> validate_required([:offer_id, :partner_id])
  end
end
