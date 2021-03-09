defmodule OmegaBravera.Offers.OfferGpsCoordinate do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.Offer

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "offer_gps_coordinates" do
    field :address, :string
    field :geom, Geo.PostGIS.Geometry
    field :longitude, :decimal, virtual: true
    field :latitude, :decimal, virtual: true
    field :remove, :boolean, virtual: true, default: false

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
    |> cast(attrs, [:address, :latitude, :longitude, :offer_id])
    |> validate_length(:address, max: 255)
    |> validate_required([:address, :latitude, :longitude])
    |> cast_geom()
    |> mark_for_delete()
    |> validate_geom(partner_location)
  end

  defp cast_geom(changeset) do
    case changeset do
      %{valid?: true, changes: %{longitude: longitude, latitude: latitude}} ->
        put_change(changeset, :geom, %Geo.Point{
          coordinates: {Decimal.to_float(longitude), Decimal.to_float(latitude)},
          srid: 4326
        })

      _ ->
        changeset
    end
  end

  defp mark_for_delete(changeset) do
    if get_change(changeset, :remove) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end

  defp validate_geom(changeset, partner_location) do
    case changeset do
      %{valid?: false, errors: [latitude: _lat_error, longitude: _long_error]} ->
        if not is_nil(partner_location.geom) do
          %{changeset | valid?: true}
        else
          changeset
        end

      _ ->
        changeset
    end
  end
end
