defmodule OmegaBravera.Offers.OfferLocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.Offer
  alias OmegaBravera.Locations.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "offer_locations" do
    belongs_to :offer, Offer
    belongs_to :location, Location

    timestamps()
  end

  @doc false
  def changeset(offer_location, attrs) do
    offer_location
    |> cast(attrs, [:offer_id, :location_id])
    |> validate_required([:offer_id, :location_id])
  end
end