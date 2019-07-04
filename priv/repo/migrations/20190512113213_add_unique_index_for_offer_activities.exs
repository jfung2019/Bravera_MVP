defmodule OmegaBravera.Repo.Migrations.AddUniqueIndexForOfferActivities do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.Repo

  def up do
    from(a in "offer_challenge_activities",
      join: a2 in "offer_challenge_activities",
      on:
        a2.strava_id == a.strava_id and
          a2.offer_challenge_id == a.offer_challenge_id and
          a2.id < a.id
    )
    |> Repo.delete_all()

    create(unique_index(:offer_challenge_activities, [:strava_id, :offer_challenge_id]))
  end

  def down do
    drop(unique_index(:offer_challenge_activities, [:strava_id, :offer_challenge_id]))
  end
end
