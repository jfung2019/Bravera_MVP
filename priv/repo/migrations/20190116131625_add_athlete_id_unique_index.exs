defmodule OmegaBravera.Repo.Migrations.AddAthleteIdUniqueIndex do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Trackers.Strava}

  def up do
    from(s in Strava, where: s.athlete_id == 33762738) |> Repo.delete_all

    create unique_index(:stravas, [:athlete_id])
  end

  def down do
    drop unique_index(:stravas, [:athlete_id])
  end
end
