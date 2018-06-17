defmodule OmegaBraveraWeb.StravaController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Guardian
  alias OmegaBravera.Accounts

  def authenticate(conn, _params) do
    redirect conn, external: Strava.Auth.authorize_url!(scope: "view_private")
  end

  @doc """
  This action is reached via `/auth/callback` and is the the callback URL that Strava will redirect the user back to with a `code` that will be used to request an access token.
  The access token will then be used to access protected resources on behalf of the user.
  """

  # Make separate Strava params for a Strava record, create email if email doesn't exist?

  # Would have to make function to check if user is logged in already to add Strava to fitness provider

  def strava_callback(conn, %{"code" => code}) do
    client = Strava.Auth.get_token!(code: code)
    athlete = Strava.Auth.get_athlete!(client)

    %{token: %{access_token: access_token}} = client

    %{email: athlete_email, firstname: athlete_firstname, lastname: athlete_lastname, id: athlete_id_int} = athlete

    athlete_id = to_string(athlete_id_int)

    params = %{token: access_token, email: athlete_email, firstname: athlete_firstname, lastname: athlete_lastname, athlete_id: athlete_id}

    conn
      |> login(params)
      |> redirect(to: "/")
  end

# have to do a case to handle user connecting strava

  defp login(conn, changeset) do
    case Accounts.insert_or_update_strava_user(changeset) do
      {:ok, result} ->
        # NOTE what does match? do and is it optimal?
        cond do
        match?(%{id: _}, result) ->
          conn
          |> put_flash(:info, "Welcome!")
          |> Guardian.Plug.sign_in(result)
        match?(%{strava: _}, result) ->
          %{user: result_user} = result

          conn
          |> put_flash(:info, "Welcome!")
          |> Guardian.Plug.sign_in(result_user)
        end
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Error signing in")
    end
  end

  def logout(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: "/")
  end
end
