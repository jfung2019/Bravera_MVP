defmodule OmegaBravera.Offers.OfferLocation do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.ChangesetHelper

  alias OmegaBravera.Offers.Offer
  alias OmegaBravera.Locations.Location

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "offer_locations" do
    field :remove, :boolean, virtual: true, default: false

    belongs_to :offer, Offer
    belongs_to :location, Location

    timestamps()
  end

  @doc false
  def changeset(offer_location, attrs) do
    offer_location
    |> cast(attrs, [:offer_id, :location_id])
    |> validate_required([:offer_id, :location_id])
    |> unique_constraint(:location_id, name: :offer_locations_offer_id_location_id_index)
    |> foreign_key_constraint(:location_id, name: :offer_locations_location_id_fkey)
  end

  def assoc_changeset(offer_location, attrs) do
    offer_location
    |> cast(attrs, [:offer_id, :location_id, :remove])
    |> validate_required([:location_id])
    |> unique_constraint(:location_id, name: :offer_locations_offer_id_location_id_index)
    |> foreign_key_constraint(:location_id, name: :offer_locations_location_id_fkey)
    |> mark_for_delete()
  end
end
