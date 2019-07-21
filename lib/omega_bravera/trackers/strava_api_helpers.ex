defmodule OmegaBravera.Trackers.StravaApiHelpers do
  require Logger

  alias OmegaBravera.{Accounts}
  alias OmegaBravera.Trackers.Strava, as: StravaTracker

  def process_strava_webhook(
        %{"aspect_type" => "create", "object_type" => "activity", "owner_id" => athlete_id} =
          params
      ) do
    Logger.info("IngestionProcessor: Strava POST webhook processing: #{inspect(params)}")

    athlete_id
    |> Accounts.get_strava_by_athlete_id()
    |> get_strava_activity(params)
  end

  def process_strava_webhook(_), do: {:error, :webhook_not_processed}

  defp get_strava_activity(%StravaTracker{token: token}, %{"object_id" => object_id}),
   do: Strava.Activities.get_activity_by_id(Strava.Client.new(token), object_id, include_all_efforts: true)

  defp get_strava_activity(nil, _), do: {:error, :no_user_matching_athlete_id}
end
