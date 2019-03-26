defmodule OmegaBraveraWeb.UserEmailVerified do
  alias OmegaBravera.{Accounts.User}

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %User{email: email, email_verified: true} when not is_nil(email) ->
        conn

      %User{email: email} ->
        conn
        |> Plug.Conn.put_session(:after_email_verify, conn.request_path)
        |> Phoenix.Controller.put_view(OmegaBraveraWeb.SharedView)
        |> Phoenix.Controller.render("verify_email.html", email: email)
        |> Plug.Conn.halt()

      _ ->
        conn
    end
  end
end
