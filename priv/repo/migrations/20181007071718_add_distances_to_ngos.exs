defmodule OmegaBravera.Repo.Migrations.AddDistancesToNgos do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add :distances, {:array, :integer}, null: false, default: fragment("ARRAY[50, 75, 150, 250]")
    end
  end
end
