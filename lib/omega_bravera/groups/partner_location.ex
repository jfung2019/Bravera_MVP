defmodule OmegaBravera.Groups.PartnerLocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "partner_locations" do
    field :address, :string
    field :latitude, :decimal
    field :longitude, :decimal
    belongs_to :partner, OmegaBravera.Groups.Partner

    timestamps()
  end

  @doc false
  def changeset(partner_location, attrs) do
    partner_location
    |> cast(attrs, [:address, :latitude, :longitude, :partner_id])
    |> validate_length(:address, max: 255)
    |> validate_required([:address, :latitude, :longitude])
  end
end
