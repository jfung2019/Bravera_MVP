defmodule OmegaBravera.Offers.OfferVendor do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.Offer

  schema "offer_vendors" do
    field(:vendor_id, :string)
    field(:email, :string)

    has_many(:offers, Offer, foreign_key: :vendor_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(offer_vendor, attrs) do
    offer_vendor
    |> cast(attrs, [:vendor_id, :email])
    |> validate_required([:vendor_id, :email])
    |> unique_constraint(:vendor_id)
  end
end
