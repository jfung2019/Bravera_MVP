defmodule OmegaBravera.Repo.Migrations.AlterStravaProfilePicture do
  use Ecto.Migration

  def change do
    rename(table("stravas"), :profile_picture, to: :strava_profile_picture)
  end
end
