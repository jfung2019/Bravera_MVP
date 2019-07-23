defmodule OmegaBravera.Accounts.Strava do
  alias Ecto.Multi
  alias OmegaBravera.{Repo, Accounts, Trackers, Accounts.Notifier}

  def login_changeset(%{"code" => code}) do
    client = Strava.Auth.get_token!(code: code, grant_type: "authorization_code")
    athlete = Strava.Auth.get_athlete!(client)
    {:ok, token_expires_at} = DateTime.from_unix(client.token.expires_at)

    athlete
    |> Map.take([:firstname, :lastname])
    |> Map.put(:athlete_id, athlete.id)
    |> Map.put(:strava_profile_picture, athlete.profile)
    |> Map.merge(%{token: client.token.access_token})
    |> Map.merge(%{refresh_token: client.token.refresh_token})
    |> Map.merge(%{token_expires_at: token_expires_at})
    |> Map.put(:additional_info, build_additional_info(athlete))
  end

  # Not used at moment with accounts.insert_or_update_strava_user()
  def create_user_with_tracker_and_email(attrs) do
    case create_user_with_tracker(attrs) do
      {:ok, data} ->
        Notifier.send_user_signup_email(data[:user])
        {:ok, data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_user_with_tracker(attrs) do
    Multi.new()
    |> Multi.run(:user, fn _repo, _changes -> do_create_user(attrs) end)
    |> Multi.run(:strava, fn _repo, %{user: user} -> do_create_tracker(user, attrs) end)
    |> Repo.transaction()
  end

  defp do_create_user(attrs), do: Accounts.create_user(attrs)
  defp do_create_tracker(user, attrs), do: Trackers.create_strava(user.id, attrs)

  defp build_additional_info(%Strava.DetailedAthlete{} = athlete) do
    %{sex: athlete.sex, location: "#{athlete.country}/#{athlete.city}/#{athlete.city}"}
  end
end
