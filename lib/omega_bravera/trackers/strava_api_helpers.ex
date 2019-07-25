defmodule OmegaBravera.Trackers.StravaApiHelpers do
  require Logger

  alias OmegaBravera.{Accounts, Trackers}
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

  defp get_strava_activity(%StravaTracker{token: token, refresh_token: refresh_token} = athlete, %{"object_id" => object_id}) do
    client = Strava.Client.new(token,
      refresh_token: refresh_token,
      token_refreshed: fn client ->
        attrs = %{
          token: client.token.access_token,
          refresh_token: client.token.refresh_token,
          token_expires_at: Timex.from_unix(client.token.expires_at)
        }

        case Trackers.update_strava(athlete, attrs) do
          {:ok, _} ->
            Logger.info("Successfully refreshed token for strava athlete: #{athlete.firstname} #{athlete.lastname} #{athlete.athlete_id}")

          {:error, reason} ->
            Logger.warn("Failed to refresh token, reason: #{inspect(reason)}.")
        end
      end
    )

    Strava.Activities.get_activity_by_id(client, object_id, include_all_efforts: true)
  end

  defp get_strava_activity(nil, _), do: {:error, :no_user_matching_athlete_id}
end
