defmodule OmegaBravera.Repo.Migrations.AddChallengeTypesToNgoChal do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      add(:type, :string, null: false, default: "PER_MILESTONE")
    end
  end
end
