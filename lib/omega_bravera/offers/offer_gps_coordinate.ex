defmodule OmegaBravera.Offers.OfferGpsCoordinate do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.Offer

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "offer_gps_coordinates" do
    field :address, :string
    field :latitude, :decimal
    field :longitude, :decimal

    belongs_to :offer, Offer

    timestamps()
  end

  @doc false
  def changeset(partner_location, attrs) do
    partner_location
    |> cast(attrs, [:address, :latitude, :longitude, :offer_id])
    |> validate_length(:address, max: 255)
    |> validate_required([:address, :latitude, :longitude, :offer_id])
  end
end