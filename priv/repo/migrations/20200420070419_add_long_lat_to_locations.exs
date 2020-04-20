defmodule OmegaBravera.Repo.Migrations.AddLongLatToLocations do
  use Ecto.Migration

  def change do
    alter table("locations") do
      add :latitude, :decimal
      add :longitude, :decimal
    end
  end
end
