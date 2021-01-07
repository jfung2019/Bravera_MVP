defmodule OmegaBravera.Repo.Migrations.CreateOrganizationMembers do
  use Ecto.Migration

  def up do
    create table(:organization_members, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :partner_user_id, references(:partner_users, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create unique_index(:organization_members, [:organization_id, :partner_user_id])

    alter table(:partners) do
      remove :partner_user_id
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :nilify_all)
    end
  end

  def down do
    alter table(:partners) do
      add :partner_user_id, references(:partner_users, type: :binary_id, on_delete: :nilify_all)
      remove :organization_id
    end

    drop table(:organization_members)
  end
end
