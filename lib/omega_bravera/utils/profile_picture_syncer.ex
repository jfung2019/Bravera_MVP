defmodule OmegaBravera.ProfilePictureSyncer do
  require Logger

  alias OmegaBravera.{Trackers}

  def sync() do
    Logger.info("ProfilePictureSyncer: started..")

    stravas = Trackers.list_stravas()

    Enum.map(stravas, fn strava ->
      profile_picture = get_profile_picture_link(strava)

      case Trackers.update_strava(strava, %{profile_picture: profile_picture}) do
        {:ok, _} ->
          Logger.info("ProfilePictureSyncer: updated #{inspect(strava.email)}'s profile picture'")

        {:error, reason} ->
          Logger.error(
            "ProfilePictureSyncer: failed to update profile picture. Reason: #{inspect(reason)}"
          )
      end
    end)

    Logger.info("ProfilePictureSyncer: done!")
  end

  def get_profile_picture_link(%Trackers.Strava{} = strava) do
    case Strava.Athletes.get_logged_in_athlete(
           Trackers.StravaApiHelpers.get_strava_client(strava)
         ) do
      {:ok, athlete} ->
        athlete.profile

      {:error, reason} ->
        Logger.error("ProfilePictureSyncer: Could not get athlete, reason: #{inspect(reason)}.")
    end
  end
end
