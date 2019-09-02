defmodule OmegaBravera.Locations.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "locations" do
    field(:name_en, :string)
    field(:name_zh, :string)

    timestamps()
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [:name_en, :name_zh])
    |> validate_required([:name_en, :name_zh])
  end
end
