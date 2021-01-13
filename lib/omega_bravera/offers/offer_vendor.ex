defmodule OmegaBravera.Offers.OfferVendor do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.Offer

  schema "offer_vendors" do
    field :vendor_id, :string
    field :email, :string
    field :cc, :string

    belongs_to :organization, OmegaBravera.Accounts.Organization, type: :binary_id
    has_many :offers, Offer, foreign_key: :vendor_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(offer_vendor, attrs) do
    offer_vendor
    |> cast(attrs, [:vendor_id, :email, :cc, :organization_id])
    |> validate_required([:vendor_id])
    |> unique_constraint(:vendor_id)
  end

  def org_changeset(offer_vendor, attrs) do
    changeset(offer_vendor, attrs)
    |> validate_required([:organization_id])
  end
end
