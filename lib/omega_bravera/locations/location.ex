defmodule OmegaBravera.Locations.Location do
  use Ecto.Schema
  import Ecto.Changeset
  import OmegaBravera.ChangesetHelper

  schema "locations" do
    field :name_en, :string
    field :name_zh, :string
    field :geom, Geo.PostGIS.Geometry
    field :latitude, :decimal, virtual: true
    field :longitude, :decimal, virtual: true

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name_en, :name_zh, :latitude, :longitude])
    |> validate_required([:name_en, :name_zh, :latitude, :longitude])
    |> cast_geom()
  end
end
