defmodule OmegaBravera.Offers.OfferGpsCoordinate do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.ChangesetHelper

  alias OmegaBravera.Offers.Offer

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "offer_gps_coordinates" do
    field :address, :string
    field :geom, Geo.PostGIS.Geometry
    field :longitude, :decimal, virtual: true
    field :latitude, :decimal, virtual: true
    field :remove, :boolean, virtual: true, default: false
    field :can_access, :boolean, virtual: true

    belongs_to :offer, Offer

    timestamps()
  end

  @doc false
  def changeset(partner_location, attrs) do
    partner_location
    |> cast(attrs, [:address, :latitude, :longitude, :offer_id])
    |> validate_length(:address, max: 255)
    |> validate_required([:address, :latitude, :longitude, :offer_id])
    |> cast_geom()
  end

  def assoc_changeset(partner_location, attrs) do
    partner_location
    |> cast(attrs, [:address, :latitude, :longitude, :offer_id, :remove])
    |> validate_length(:address, max: 255)
    |> validate_required([:address, :latitude, :longitude])
    |> cast_geom()
    |> mark_for_delete()
  end
end
