defmodule OmegaBravera.Repo.Migrations.ChangeLongLatToGeom do
  use Ecto.Migration

  def change do
    alter table("locations") do
      add :geom, :geography
    end

    alter table("partner_locations") do
      add :geom, :geography
    end

    flush()

    execute "UPDATE locations SET latitude=22.3193, longitude=114.1694 WHERE id=1;", ""

    execute "UPDATE locations SET latitude=12.1784, longitude=68.2385 WHERE id=9;", ""

    execute "UPDATE locations SET geom=ST_GeomFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);"

    execute "UPDATE partner_locations SET geom=ST_GeomFromText('POINT(' || longitude || ' ' || latitude || ')', 4326);"

    flush()

    alter table("locations") do
      modify :geom, :geography, null: false
      remove :latitude
      remove :longitude
    end

    alter table("partner_locations") do
      modify :geom, :geography, null: false
      remove :latitude
      remove :longitude
    end
  end
end
