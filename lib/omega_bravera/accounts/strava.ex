defmodule OmegaBravera.Accounts.Strava do
  alias Ecto.Multi
  alias OmegaBravera.{Repo, Accounts, Accounts.User, Trackers, Accounts.Notifier}
  alias SendGrid.{Email, Mailer}

  def login_changeset(%{"code" => code}) do
    client = Strava.Auth.get_token!(code: code)
    athlete = Strava.Auth.get_athlete!(client)

    athlete
    |> Map.take([:email, :firstname, :lastname])
    |> Map.put(:athlete_id, athlete.id)
    |> Map.merge(%{token: client.token.access_token})
    |> Map.put(:additional_info, build_additional_info(athlete))
  end

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
    Multi.new
    |> Multi.run(:user, &(do_create_user(&1, attrs)))
    |> Multi.run(:strava, &(do_create_tracker(&1, attrs)))
    |> Repo.transaction()
  end

  defp do_create_user(_, attrs), do: Accounts.create_user(attrs)
  defp do_create_tracker(%{user: user}, attrs), do: Trackers.create_strava(user.id, attrs)

  defp build_additional_info(%Strava.Athlete.Summary{} = athlete) do
    %{sex: athlete.sex, location: "#{athlete.country}/#{athlete.city}/#{athlete.city}"}
  end
end
