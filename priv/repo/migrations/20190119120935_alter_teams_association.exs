defmodule OmegaBravera.Repo.Migrations.AlterTeamsAssociation do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      remove :team_id
    end

    alter table(:teams) do
      remove :activity
      remove :location
      remove :ngo_id
      add :slug, :string, null: false
      add :challenge_id, references("ngo_chals"), null: false
    end

    # Drop useless challenge index
    drop index(:ngo_chals, [:ngo_id, :slug])
    # Make sure challenge.slug is unique
    create unique_index(:ngo_chals, [:slug], name: :ngo_chals_slug_unique_index)

    create unique_index(:teams, [:slug])
    # Each team can only belong to a single challenge.
    create unique_index(:teams, [:challenge_id])

  end
end
