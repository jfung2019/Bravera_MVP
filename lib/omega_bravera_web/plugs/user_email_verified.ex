defmodule OmegaBraveraWeb.UserEmailVerified do
  alias OmegaBravera.{Accounts.User}

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %User{email: email} when is_nil(email) ->
        conn
        |> Phoenix.Controller.put_view(OmegaBraveraWeb.SharedView)
        |> Phoenix.Controller.render("verify_email.html", email: email)
        |> Plug.Conn.halt()

      %User{email: email, email_verified: false} when not is_nil(email) ->
        conn
        |> Phoenix.Controller.put_view(OmegaBraveraWeb.SharedView)
        |> Phoenix.Controller.render("verify_email.html", email: email)
        |> Plug.Conn.halt()

      _ ->
        conn
    end
  end
end
