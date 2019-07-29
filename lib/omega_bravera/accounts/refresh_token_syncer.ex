defmodule OmegaBravera.Accounts.RefreshTokenSyncer do
  require Logger

  alias OmegaBravera.{Trackers}

  def start() do
    Logger.info("RefreshTokenSyncer: started..")

    stravas = Trackers.list_stravas()

    Enum.map(stravas, fn strava ->
      try do
        client = Strava.Auth.get_token!(grant_type: "refresh_token", refresh_token: strava.token)

        case Trackers.update_strava(strava, %{
               token: client.token.access_token,
               refresh_token: client.token.refresh_token,
               token_expires_at: Timex.from_unix(client.token.expires_at)
             }) do
          {:ok, _} ->
            Logger.info("RefreshTokenSyncer: updated #{inspect(strava.strava_id)}'s tokens.")

          {:error, reason} ->
            Logger.error("RefreshTokenSyncer: failed to update. Reason: #{inspect(reason)}")
        end
      rescue
        exception ->
          Logger.warn(
            "RefreshTokenSyncer: Could not get new tokens for athlete: #{inspect(strava)}: #{inspect(exception)}"
          )
      end
    end)

    Logger.info("RefreshTokenSyncer: done!")
  end
end
