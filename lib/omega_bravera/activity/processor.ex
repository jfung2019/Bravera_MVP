defmodule OmegaBravera.Activity.Processor do
  require Logger

  alias OmegaBravera.{Repo, Accounts, Activity.Activities}

  def process_activity(%Strava.Activity{} = strava_activity, athlete_id) do
    user = Accounts.get_strava_by_athlete_id(athlete_id) |> Repo.preload(:user)

    case Activities.create_activity(strava_activity, user) do
      {:ok, _activity} ->
        Logger.info("ActivityProcessor: Saved a new activity for user #{user.id}")

        # TODO: Spawn two tasks: a- ActivitiesIngestion b- OfferActivitiesIngestion -Sherief

      {:error, reason} ->
        Logger.info("ActivityProcessor: I received a new activity from Strava but could not save it. Reason: #{inspect(reason)}")
    end
  end
end
