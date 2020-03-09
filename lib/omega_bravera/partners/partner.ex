defmodule OmegaBravera.Partners.Partner do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Partners.PartnerLocation

  schema "partners" do
    field :images, {:array, :string}, default: []
    field :introduction, :string
    field :name, :string
    field :opening_times, :string
    has_one :location, PartnerLocation

    timestamps()
  end

  @doc false
  def changeset(partner, attrs) do
    partner
    |> cast(attrs, [:name, :introduction, :opening_times, :images])
    |> validate_length(:introduction, max: 255)
    |> validate_length(:name, max: 255)
    |> validate_required([:name, :introduction, :opening_times, :images])
    |> put_blank_location()
  end

  def change_changeset(partner, attrs) do
    partner
    |> cast(attrs, [])
  end

  defp put_blank_location(changeset) do
    case get_field(changeset, :location) do
      nil ->
        put_assoc(changeset, :location, nil)
      _ ->
        cast_assoc(changeset, :location, required: false)
    end
  end
end
