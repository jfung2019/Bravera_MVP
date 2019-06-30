defmodule OmegaBravera.Repo.Migrations.MigrateActivities do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Challenges.Activity, Offers.OfferChallengeActivity}

  def up do
    # Get all ngo challenge activities and save them into activities_accumulator.
    Repo.update_all(from(a in Activity, where: is_nil(a.strava_id) and not is_nil(a.admin_id)),
      set: [manual: true]
    )

    Repo.query!(
      "INSERT INTO activities_accumulator (strava_id, name, distance, start_date, manual, type, moving_time, average_speed, elapsed_time, calories, user_id, admin_id, inserted_at, updated_at, source)
    SELECT distinct on (strava_id) a.strava_id, a.name, a.distance, a.start_date, a.manual, a.type, a.moving_time, a.average_speed, a.elapsed_time, a.calories, a.user_id, a.admin_id, a.inserted_at, a.updated_at, 'strava'
    FROM activities as a
    WHERE admin_id is null;"
    )

    # Create many to many relation ship between activities_accumulator and ngo_challenge_activities_m2m
    Repo.query!("INSERT INTO ngo_challenge_activities_m2m (id, activity_id, challenge_id)
    SELECT md5(random()::text || clock_timestamp()::text)::uuid, ac.id, a.challenge_id
    FROM activities_accumulator AS ac
    JOIN activities AS a
    ON a.strava_id = ac.strava_id")

    # Get all offer challenge activities that are not in activities and save them into activities_accumulator:
    Repo.update_all(
      from(a in OfferChallengeActivity, where: is_nil(a.strava_id) and not is_nil(a.admin_id)),
      set: [manual: true]
    )

    Repo.query!(
      "INSERT INTO activities_accumulator (strava_id, name, distance, start_date, manual, type, moving_time, average_speed, elapsed_time, calories, user_id, admin_id, inserted_at, updated_at, source)
    SELECT distinct on (strava_id) a.strava_id, a.name, a.distance, a.start_date, a.manual, a.type, a.moving_time, a.average_speed, a.elapsed_time, a.calories, a.user_id, a.admin_id, a.inserted_at, a.updated_at, 'strava'
    FROM offer_challenge_activities as a
    WHERE admin_id is null and strava_id not in (select distinct on(strava_id) strava_id from activities_accumulator);"
    )

    # Create many to many relation ship between activities_accumulator and offer_challenge_activities_m2m
    Repo.query!("INSERT INTO offer_challenge_activities_m2m (id, activity_id, offer_challenge_id)
    SELECT md5(random()::text || clock_timestamp()::text)::uuid, ac.id, a.offer_challenge_id
    FROM activities_accumulator AS ac
    JOIN offer_challenge_activities AS a
    ON a.strava_id = ac.strava_id")
  end

  def down do
    Repo.query("TRUNCATE activities_accumulator CASCADE", [])
    Repo.query("TRUNCATE ngo_challenge_activities_m2m CASCADE", [])
    Repo.query("TRUNCATE offer_challenge_activities_m2m CASCADE", [])
  end
end
