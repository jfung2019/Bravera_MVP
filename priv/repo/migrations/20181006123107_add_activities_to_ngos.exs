defmodule OmegaBravera.Repo.Migrations.AddActivitiesToNgos do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add(:activities, {:array, :string},
        null: false,
        default: fragment("ARRAY['Run', 'Cycle', 'Walk', 'Hike']")
      )
    end
  end
end
