defmodule OmegaBravera.Repo.Migrations.CreateGroupAreas do
  use Ecto.Migration

  def change do
    alter table("partners") do
      add :location_id, references(:locations, on_delete: :delete_all)
    end
  end
end
