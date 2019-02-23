defmodule OmegaBravera.Repo.Migrations.MigrateStravaIdToBigint do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      modify(:strava_id, :bigint)
    end
  end
end
