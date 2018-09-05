defmodule OmegaBravera.Accounts.Strava do
  alias Ecto.Multi
  alias OmegaBravera.{Repo, Accounts, Accounts.User, Trackers}
  alias SendGrid.{Email, Mailer}

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
    case create_user_with_tracker(attrs) do
      {:ok, data} ->
        Mailer.send(build_email(data[:user]))
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

  def build_email(%Accounts.User{} = user) do
    Email.build()
    |> Email.put_template("b47d2224-792a-43d8-b4b2-f53b033d2f41")
    |> Email.add_substitution("-fullName-",Accounts.User.full_name(user))
    |> Email.put_from("admin@bravera.co")
    |> Email.add_to(user.email)
  end

  defp do_create_user(_, attrs), do: Accounts.create_user(attrs)
  defp do_create_tracker(%{user: user}, attrs), do: Trackers.create_strava(user.id, attrs)
end
