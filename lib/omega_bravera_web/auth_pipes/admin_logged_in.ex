defmodule OmegaBraveraWeb.AdminLoggedIn do
  alias OmegaBravera.Accounts.AdminUser

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        conn
      _ ->
        Plug.Conn.halt(conn)
    end
  end
end