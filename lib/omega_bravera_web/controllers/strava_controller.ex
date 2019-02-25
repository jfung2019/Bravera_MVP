defmodule OmegaBraveraWeb.StravaController do
  require Logger
  use OmegaBraveraWeb, :controller
  alias URI

  alias OmegaBravera.{Guardian, Accounts, Challenges.ActivitiesIngestion}

  def post_webhook_callback(conn, params) do
    ActivitiesIngestion.process_strava_webhook(params)
    render(conn, "webhook_callback.json", status: 200)
  end

  def get_webhook_callback(conn, params) do
    render(conn, "hub_challenge.json", hub_challenge: params["hub.challenge"])
  end

  def authenticate(conn, %{"team_invitation" => team_invitation}) do
    redirect_url =
      OmegaBraveraWeb.Endpoint.url() <> "/strava/callback?redirect_to=#{team_invitation}"

    redirect(conn,
      external: Strava.Auth.authorize_url!(scope: "view_private", redirect_uri: redirect_url)
    )
  end

  def authenticate(conn, _params) do
    redirect_url =
      OmegaBraveraWeb.Endpoint.url() <> "/strava/callback?redirect_to=" <> get_redirect_url(conn)

    redirect(conn,
      external: Strava.Auth.authorize_url!(scope: "view_private", redirect_uri: redirect_url)
    )
  end

  @doc """
  This action is reached via `/auth/callback` and is the the callback URL that Strava will redirect the user back to with a `code` that will be used to request an access token.
  The access token will then be used to access protected resources on behalf of the user.
  """
  # Make separate Strava params for a Strava record, create email if email doesn't exist?
  # Would have to make function to check if user is logged in already to add Strava to fitness provider
  def strava_callback(conn, params) do
    conn
    |> login(Accounts.Strava.login_changeset(params))
    |> redirect(to: params["redirect_to"])
  end

  # have to do a case to handle user connecting strava
  defp login(conn, changeset) do
    case Accounts.insert_or_update_strava_user(changeset) do
      {:ok, result} ->
        login_params =
          cond do
            match?(%{id: _}, result) -> result
            match?(%{strava: _}, result) -> result[:user]
          end

        conn
        |> put_flash(:info, "Welcome!")
        |> Guardian.Plug.sign_in(login_params)

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

  defp get_redirect_url(conn) do
    # Return the user back the very last page he was on (used only for logins in the :ngo/:ngo_chal/new page)
    try do
      uri =
        conn
        |> Plug.Conn.get_req_header("referer")
        |> List.first()
        |> URI.parse()

      path =
        case uri.path do
          "/oauth/authorize" ->
            "/"

          _ ->
            uri.path
        end

      path
    rescue
      _ ->
        "/"
    end
  end
end
