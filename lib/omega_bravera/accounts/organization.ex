defmodule OmegaBravera.Accounts.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "organizations" do
    field :name, :string
    field :business_type, :string
    field :member_count, :integer, virtual: true

    has_many :groups, OmegaBravera.Groups.Partner
    has_many :group_members, through: [:groups, :members]
    has_many :group_users, through: [:group_members, :user]
    has_many :offers, OmegaBravera.Offers.Offer
    has_many :points, OmegaBravera.Points.Point
    has_many :organization_members, OmegaBravera.Accounts.OrganizationMember

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :business_type])
    |> validate_required([:name, :business_type])
  end
end
