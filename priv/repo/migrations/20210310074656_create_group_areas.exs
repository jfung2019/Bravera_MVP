defmodule OmegaBravera.Repo.Migrations.CreateGroupAreas do
  use Ecto.Migration

  def change do
    create table("group_areas",  primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_id, references(:partners, on_delete: :delete_all), null: false
      add :location_id, references(:locations, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:group_areas, [:group_id, :location_id])
  end
end
