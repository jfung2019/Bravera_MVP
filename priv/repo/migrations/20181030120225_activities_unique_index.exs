defmodule OmegaBravera.Repo.Migrations.ActivitiesUniqueIndex do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Challenges.Activity}

  def up do
    from(a in Activity,
      join: a2 in Activity,
      on:
        a2.strava_id == a.strava_id and
          a2.challenge_id == a.challenge_id and
          a2.id < a.id
    )
    |> Repo.delete_all()

    create(unique_index(:activities, [:strava_id, :challenge_id]))
  end

  def down do
    drop(unique_index(:activities, [:strava_id, :challenge_id]))
  end
end
