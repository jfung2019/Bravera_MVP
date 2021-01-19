defmodule OmegaBravera.Accounts.OrganizationMember do
  use Ecto.Schema
  import Ecto.Changeset
  alias OmegaBravera.Accounts.{Organization, PartnerUser}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "organization_members" do
    belongs_to :organization, Organization, type: :binary_id
    belongs_to :partner_user, PartnerUser, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(organization_member, attrs) do
    organization_member
    |> cast(attrs, [:organization_id, :partner_user_id])
    |> validate_required([:organization_id, :partner_user_id])
  end

  def register_changeset(organization_member, attrs) do
    organization_member
    |> cast(attrs, [])
    |> cast_assoc(:partner_user, with: &PartnerUser.changeset/2, required: true)
    |> update_org()
    |> cast_assoc(:organization, with: &Organization.changeset/2, required: true)
  end

  defp update_org(
         %{changes: %{partner_user: %{valid?: true, changes: %{username: username}}}} = changeset
       ) do
    %{changeset | params: put_in(changeset.params, ["organization", "name"], "#{username} Org.")}
  end

  defp update_org(changeset), do: changeset
end
