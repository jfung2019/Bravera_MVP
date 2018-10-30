defmodule OmegaBravera.Repo.Migrations.AddActivityObjectId do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :object_id, :integer, null: true, default: nil
    end

    create unique_index(:activities, [:object_id])
  end
end
