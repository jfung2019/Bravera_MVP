defmodule OmegaBravera.Repo.Migrations.AddActivityCalories do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :calories, :decimal, default: 0
    end
  end
end
