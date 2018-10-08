defmodule OmegaBraveraWeb.StravaController do
  require Logger
  use OmegaBraveraWeb, :controller
  alias URI

  alias OmegaBravera.{Guardian, Accounts, Challenges.ActivitiesIngestion}

  # TODO Check if activity was manual update or GPS upload
  # Is upload_id only for file uploads?
  # upload_id: 123123123121
  #
  # Is created_at nil only for file updates or also for third-party trackers?
  # created_at: nil

  def post_webhook_callback(conn, params) do
    ActivitiesIngestion.process_strava_webhook(params)
    render(conn, "webhook_callback.json", status: "200")
  end

  def get_webhook_callback(conn, params) do
    render(conn, "hub_challenge.json", hub_challenge: params["hub.challenge"])
  end

  def authenticate(conn, _params) do
    redirect(conn, external: Strava.Auth.authorize_url!(scope: "view_private"))
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
    |> redirect(to: get_redirect_url(conn))
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
    try do
      uri =
        conn
        |> Plug.Conn.get_req_header("referer")
        |> List.first()
        |> URI.parse()

      uri.path
    rescue
      _ ->
        "/"
    end
  end
end
