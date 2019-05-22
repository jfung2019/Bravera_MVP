defmodule OmegaBraveraWeb.ConnectTracker do
  alias OmegaBravera.{Accounts.User}

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %User{strava: strava} when not is_nil(strava) ->
        conn

      %User{strava: nil} ->
        conn
        |> Phoenix.Controller.put_flash(:info, "Please connect a tracker before taking a challenge")
        |> Phoenix.Controller.render(OmegaBraveraWeb.UserView, "trackers.html", user: OmegaBravera.Guardian.Plug.current_resource(conn), redirect_to: conn.request_path)
        |> Plug.Conn.halt()

      _ ->
        conn
    end
  end
end
