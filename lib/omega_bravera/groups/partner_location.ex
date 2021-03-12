defmodule OmegaBravera.Groups.PartnerLocation do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.ChangesetHelper

  schema "partner_locations" do
    field :address, :string
    field :geom, Geo.PostGIS.Geometry
    field :latitude, :decimal, virtual: true
    field :longitude, :decimal, virtual: true

    belongs_to :partner, OmegaBravera.Groups.Partner

    timestamps()
  end

  @doc false
  def changeset(partner_location, attrs) do
    partner_location
    |> cast(attrs, [:address, :latitude, :longitude, :partner_id])
    |> validate_length(:address, max: 255)
    |> validate_required([:address, :latitude, :longitude])
    |> cast_geom()
  end
end
