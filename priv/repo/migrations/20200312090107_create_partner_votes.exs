defmodule OmegaBravera.Repo.Migrations.CreatePartnerVotes do
  use Ecto.Migration

  def change do
    create table(:partner_votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :partner_id, references(:partners, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:partner_votes, [:partner_id])
    create index(:partner_votes, [:user_id])
    create unique_index(:partner_votes, [:partner_id, :user_id])
  end
end
