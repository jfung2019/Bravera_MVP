defmodule OmegaBravera.Repo.Migrations.AddOrgIdToOffer do
  use Ecto.Migration

  def up do
    alter table("offers") do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :nilify_all)
    end

    alter table("offer_vendors") do
      remove :partner_user_id
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :nilify_all)
    end
  end

  def down do
    alter table("offers") do
      remove :organization_id
    end

    alter table("offer_vendors") do
      add :partner_user_id, references(:organizations, type: :binary_id, on_delete: :nilify_all)
      remove :organization_id
    end
  end
end
