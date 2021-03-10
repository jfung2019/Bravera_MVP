defmodule OmegaBravera.Groups.GroupArea do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Locations.Location
  alias OmegaBravera.Groups.Partner

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "group_areas" do
    belongs_to :group, Partner
    belongs_to :location, Location


    timestamps()
  end

  @doc false
  def changeset(group_area, attrs) do
    group_area
    |> cast(attrs, [:group_id, :location])
    |> validate_required([:group_id, :location])
  end
end
