defmodule OmegaBravera.Repo.Migrations.DeleteStravaActivity do
  use Ecto.Migration

  import Ecto.Query

  def change do
    activity_ids =
      from(
        aa in "activities_accumulator",
        left_join: offer_activity in "offer_challenge_activities_m2m",
        on: aa.id == offer_activity.activity_id,
        left_join: ngo_activity in "ngo_challenge_activities_m2m",
        on: aa.id == ngo_activity.activity_id,
        where: not is_nil(aa.strava_id) and is_nil(offer_activity.id) and is_nil(ngo_activity.id),
        select: aa.id
      )

    from(aa in "activities_accumulator", where: aa.id in subquery(activity_ids))
    |> OmegaBravera.Repo.delete_all()
  end
end
