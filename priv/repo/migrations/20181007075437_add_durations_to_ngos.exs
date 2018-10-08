defmodule OmegaBravera.Repo.Migrations.AddDurationsToNgos do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add :durations, {:array, :integer}, null: false, default: fragment("ARRAY[30, 40, 50, 60]")
    end
  end
end
