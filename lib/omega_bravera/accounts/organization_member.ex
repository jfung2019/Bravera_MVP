defmodule OmegaBravera.Accounts.OrganizationMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "organization_members" do
    belongs_to :organization, OmegaBravera.Accounts.Organization, type: :binary_id
    belongs_to :partner_user, OmegaBravera.Accounts.PartnerUser, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(organization_member, attrs) do
    organization_member
    |> cast(attrs, [:organization_id, :partner_user_id])
    |> validate_required([:organization_id, :partner_user_id])
  end
end
