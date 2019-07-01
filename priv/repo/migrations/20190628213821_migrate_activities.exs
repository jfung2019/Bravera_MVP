defmodule OmegaBravera.Repo.Migrations.MigrateActivities do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Challenges.Activity, Offers.OfferChallengeActivity}

  def up do

    Repo.query!("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";")

    # Get all ngo challenge activities and save them into activities_accumulator.
    Repo.update_all(from(a in Activity, where: is_nil(a.strava_id) and not is_nil(a.admin_id)),
      set: [manual: true]
    )

    # Get all offer challenge activities that are not in activities and save them into activities_accumulator:
    Repo.update_all(
      from(a in OfferChallengeActivity, where: is_nil(a.strava_id) and not is_nil(a.admin_id)),
      set: [manual: true]
    )


    # ------ Fill activity accumulator START ------ #
    # NGO Strava activities
    Repo.query!(
      "INSERT INTO activities_accumulator (strava_id, name, distance, start_date, manual, type, moving_time, average_speed, elapsed_time, calories, user_id, admin_id, inserted_at, updated_at, source)
      SELECT distinct on (strava_id) a.strava_id, a.name, a.distance, a.start_date, a.manual, a.type, a.moving_time, a.average_speed, a.elapsed_time, a.calories, a.user_id, a.admin_id, a.inserted_at, a.updated_at, 'strava'
      FROM activities as a
      WHERE admin_id is null;"
    )

    # Offer Strava activities
    Repo.query!(
      "INSERT INTO activities_accumulator (strava_id, name, distance, start_date, manual, type, moving_time, average_speed, elapsed_time, calories, user_id, admin_id, inserted_at, updated_at, source)
      SELECT distinct on (strava_id) a.strava_id, a.name, a.distance, a.start_date, a.manual, a.type, a.moving_time, a.average_speed, a.elapsed_time, a.calories, a.user_id, a.admin_id, a.inserted_at, a.updated_at, 'strava'
      FROM offer_challenge_activities as a
      WHERE admin_id is null and strava_id not in (select strava_id from activities_accumulator);"
    )

    # NGO Manual Activities - Admin created
    Repo.query!(
      "INSERT INTO activities_accumulator (strava_id, name, distance, start_date, manual, type, moving_time, average_speed, elapsed_time, calories, user_id, admin_id, inserted_at, updated_at, source)
      SELECT distinct on (id) a.strava_id, a.name, a.distance, a.start_date, a.manual, a.type, a.moving_time, a.average_speed, a.elapsed_time, a.calories, a.user_id, a.admin_id, a.inserted_at, a.updated_at, 'strava'
      FROM activities as a
      WHERE strava_id is null;"
    )

    # Offer Manual Activities - Admin created
    Repo.query!(
      "INSERT INTO activities_accumulator (strava_id, name, distance, start_date, manual, type, moving_time, average_speed, elapsed_time, calories, user_id, admin_id, inserted_at, updated_at, source)
      SELECT distinct on (id) a.strava_id, a.name, a.distance, a.start_date, a.manual, a.type, a.moving_time, a.average_speed, a.elapsed_time, a.calories, a.user_id, a.admin_id, a.inserted_at, a.updated_at, 'strava'
      FROM offer_challenge_activities as a
      WHERE strava_id is null;"
    )

    # ------ Fill activity accumulator END ------ #


    # Create many to many relation ship between activities_accumulator and ngo_challenge_activities_m2m - Strava activities
    Repo.query!(
      "INSERT INTO ngo_challenge_activities_m2m (id, activity_id, challenge_id)
      SELECT uuid_generate_v4(), ac.id, a.challenge_id
      FROM activities_accumulator AS ac
      JOIN activities AS a
      ON a.strava_id = ac.strava_id;"
    )

    # Create many to many relation ship between activities_accumulator and offer_challenge_activities_m2m - Strava activities
    Repo.query!(
      "INSERT INTO offer_challenge_activities_m2m (id, activity_id, offer_challenge_id)
      SELECT uuid_generate_v4(), ac.id, a.offer_challenge_id
      FROM activities_accumulator AS ac
      JOIN offer_challenge_activities AS a
      ON a.strava_id = ac.strava_id;"
    )

    # Create many to many relation ship between activities_accumulator and ngo_challenge_activities_m2m - Manual activities - Admin created
    Repo.query!(
      "INSERT INTO ngo_challenge_activities_m2m (id, activity_id, challenge_id)
      SELECT uuid_generate_v4(), ac.id, a.challenge_id
      FROM activities_accumulator AS ac
      JOIN activities AS a
      ON a.inserted_at = ac.inserted_at and a.updated_at = ac.updated_at and a.strava_id is null;"
    )

    # Create many to many relation ship between activities_accumulator and offer_challenge_activities_m2m - Manual activities - Admin created
    Repo.query!(
      "INSERT INTO offer_challenge_activities_m2m (id, activity_id, offer_challenge_id)
      SELECT uuid_generate_v4(), ac.id, a.offer_challenge_id
      FROM activities_accumulator AS ac
      JOIN offer_challenge_activities AS a
      ON a.inserted_at = ac.inserted_at and a.updated_at = ac.updated_at and a.strava_id is null;"
    )
  end

  def down do
    Repo.query("TRUNCATE activities_accumulator CASCADE", [])
    Repo.query("TRUNCATE ngo_challenge_activities_m2m CASCADE", [])
    Repo.query("TRUNCATE offer_challenge_activities_m2m CASCADE", [])
  end
end
