defmodule OmegaBravera.Activity.Processor do
  require Logger

  alias OmegaBravera.{
    TaskSupervisor,
    Repo,
    Accounts,
    Activity.Activities,
    Offers.OfferActivitiesIngestion,
    Challenges.ActivitiesIngestion
  }

  def process_activity(%Strava.DetailedActivity{} = strava_activity, %{"owner_id" => athlete_id} = params) do
    user = Accounts.get_strava_by_athlete_id(athlete_id) |> Repo.preload(:user)

    case Activities.create_activity(strava_activity, user) do
      {:ok, activity} ->
        Logger.info("ActivityProcessor: Saved a new activity for user #{user.id}")

        Task.Supervisor.start_child(
          TaskSupervisor,
          OfferActivitiesIngestion,
          :start,
          [activity, params],
          restart: :temporary
        )

        Task.Supervisor.start_child(
          TaskSupervisor,
          ActivitiesIngestion,
          :start,
          [activity, params],
          restart: :temporary
        )

      {:error, reason} ->
        Logger.info(
          "ActivityProcessor: I received a new activity from Strava but could not save it. Reason: #{
            inspect(reason)
          }"
        )
    end
  end
end
