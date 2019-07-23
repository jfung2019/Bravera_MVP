defmodule OmegaBraveraWeb.StravaController do
  require Logger
  use OmegaBraveraWeb, :controller
  alias URI

  alias OmegaBravera.{
    Trackers,
    Guardian,
    Accounts,
    IngestionSupervisor
  }

  def post_webhook_callback(conn, params) do
    # Start activity ingestion supervisor for challenges.
    IngestionSupervisor.start_processing(params)
    render(conn, "webhook_callback.json", status: 200)
  end

  def get_webhook_callback(conn, params) do
    render(conn, "hub_challenge.json", hub_challenge: params["hub.challenge"])
  end

  def authenticate(conn, %{"team_invitation" => team_invitation}) do
    redirect_url =
      OmegaBraveraWeb.Endpoint.url() <> "/strava/callback?redirect_to=#{team_invitation}"

    redirect(conn,
      external: Strava.Auth.authorize_url!(scope: "activity:read_all,profile:read_all", redirect_uri: redirect_url)
    )
  end

  def authenticate(conn, _params) do
    redirect_url = strava_url(conn, :strava_callback, %{redirect_to: get_redirect_url(conn)})

    redirect(conn,
      external: Strava.Auth.authorize_url!(scope: "activity:read_all,profile:read_all", redirect_uri: redirect_url)
    )
  end

  def connect_strava_account(conn, params) do
    redirect_url =
      strava_url(conn, :connect_strava_callback, %{
        redirect_to: Map.get(params, "redirect_to", "/")
      })

    redirect(conn,
      external: Strava.Auth.authorize_url!(scope: "activity:read_all,profile:read_all", redirect_uri: redirect_url)
    )
  end

  @doc """
  Adds a Strava Tracker to a Bravera User Account.
  """
  def connect_strava_callback(conn, params) do
    conn
    |> attach_strava_to_user(Accounts.Strava.login_changeset(params))
    |> redirect(to: Map.get(params, "redirect_to", "/"))
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

  defp attach_strava_to_user(conn, attrs) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_flash(
          :error,
          "You should be logged in using your Bravera account before trying to connect a Strava Tracker"
        )

      user ->
        case Trackers.create_strava(user.id, attrs) do
          {:ok, _} ->
            conn
            |> put_flash(
              :info,
              gettext(
                "Success! You have connected your Strava account and can now take Challenges."
              )
            )

          {:error, changeset} ->
            Logger.error("Could not connect strava account, reason: #{inspect(changeset)}")

            # TODO: deal with other possible cases, bust just consider account is already being used
            conn
            |> put_flash(
              :error,
              gettext(
                "Sorry, this Strava account is already connected to an exiting Bravera account"
              )
            )
        end
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
    case get_session(conn, "after_login_redirect") do
      nil ->
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

      path ->
        path
    end
  end
end
