defmodule OmegaBravera.Accounts.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "organizations" do
    field :name, :string
    field :business_type, :string
    field :member_count, :integer, virtual: true

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :business_type])
    |> validate_required([:name, :business_type])
  end
end
