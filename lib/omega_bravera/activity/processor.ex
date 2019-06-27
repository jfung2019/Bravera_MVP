defmodule OmegaBravera.Activity.Processor do
  require Logger

  alias OmegaBravera.{Repo, Accounts, Activity.Activities, Offers.OfferActivitiesIngestion}

  def process_activity(%Strava.Activity{} = strava_activity, %{"owner_id" => athlete_id} = params) do
    user = Accounts.get_strava_by_athlete_id(athlete_id) |> Repo.preload(:user)

    case Activities.create_activity(strava_activity, user) do
      {:ok, activity} ->
        Task.start(OfferActivitiesIngestion, :start, [activity, params])
        # Task.start(ActivitiesIngestion, :process_strava_webhook, [params])
        Logger.info("ActivityProcessor: Saved a new activity for user #{user.id}")

      {:error, reason} ->
        Logger.info("ActivityProcessor: I received a new activity from Strava but could not save it. Reason: #{inspect(reason)}")
    end
  end
end
