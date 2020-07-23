defmodule OmegaBravera.Repo.Migrations.CreatePartnerMembers do
  use Ecto.Migration

  def change do
    create table(:partner_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :bigserial), null: false

      add :partner_id, references(:partners, on_delete: :delete_all, type: :bigserial),
        null: false

      timestamps()
    end

    create index(:partner_members, [:user_id])
    create index(:partner_members, [:partner_id])
    create unique_index(:partner_members, [:user_id, :partner_id])
  end
end
