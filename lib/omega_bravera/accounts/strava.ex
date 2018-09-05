defmodule OmegaBravera.Accounts.Strava do
  alias Ecto.Multi
  alias OmegaBravera.Repo
  alias OmegaBravera.{Repo, Accounts, Accounts.User, Trackers}

  def login_changeset(%{"code" => code}) do
    client = Strava.Auth.get_token!(code: code)
    athlete = Strava.Auth.get_athlete!(client)

    %{token: %{access_token: token}} = client

    athlete
    |> Map.take([:email, :firstname, :lastname])
    |> Map.put(:athlete_id, athlete.id)
    |> Map.merge(%{token: token})
  end

  def create_user_with_tracker_and_email(attrs) do
    result =
      Multi.new
      |> Multi.run(:user, &(do_create_user(&1, attrs)))
      |> Multi.run(:strava, &(do_create_tracker(&1, attrs)))
      |> Repo.transaction()

    case result do
      {:ok, user} ->
        #TODO: Plug here sending signup transactional email
        {:ok, user}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_create_user(_, attrs), do: Accounts.create_user(attrs)
  defp do_create_tracker(%{user: user}, attrs), do: Trackers.create_strava(user.id, attrs)
end
