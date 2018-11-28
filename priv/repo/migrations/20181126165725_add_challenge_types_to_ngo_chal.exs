defmodule OmegaBravera.Repo.Migrations.AddChallengeTypesToNgoChal do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      add :type, :string, null: false, default: "Per Goal"
    end
  end
end
