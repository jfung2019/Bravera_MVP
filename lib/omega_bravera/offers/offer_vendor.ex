defmodule OmegaBravera.Offers.OfferVendor do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.Offer

  schema "offer_vendors" do
    field :vendor_id, :string
    field :email, :string
    field :cc, :string

    belongs_to :partner_user, OmegaBravera.Accounts.PartnerUser, type: :binary_id
    has_many :offers, Offer, foreign_key: :vendor_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(offer_vendor, attrs) do
    offer_vendor
    |> cast(attrs, [:vendor_id, :email, :cc, :partner_user_id])
    |> validate_required([:vendor_id])
    |> unique_constraint(:vendor_id)
  end
end
