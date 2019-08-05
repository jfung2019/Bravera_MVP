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

  defp get_strava_activity(%StravaTracker{} = athlete, %{"object_id" => object_id}),
    do:
      Strava.Activities.get_activity_by_id(get_strava_client(athlete), object_id,
        include_all_efforts: true
      )

  defp get_strava_activity(nil, _), do: {:error, :no_user_matching_athlete_id}

  # Access token can be used as a refresh token only pre-october 2019. -Sherief
  def get_strava_client(%StravaTracker{token: token, refresh_token: nil} = athlete),
    do: strava_client(athlete, token)

  def get_strava_client(%StravaTracker{token: _token, refresh_token: refresh_token} = athlete),
    do: strava_client(athlete, refresh_token)

  defp strava_client(athlete, refresh_token) do
    Strava.Client.new(athlete.token,
      refresh_token: refresh_token,
      token_refreshed: fn client ->
        attrs = %{
          token: client.token.access_token,
          refresh_token: client.token.refresh_token,
          token_expires_at: Timex.from_unix(client.token.expires_at)
        }

        case Trackers.update_strava(athlete, attrs) do
          {:ok, _} ->
            Logger.info(
              "StravaHelpers: Successfully refreshed token for strava athlete: #{
                athlete.firstname
              } #{athlete.lastname} #{athlete.athlete_id}"
            )

          {:error, reason} ->
            Logger.warn("StravaHelpers: Failed to refresh token, reason: #{inspect(reason)}.")
        end
      end
    )
  end
end
