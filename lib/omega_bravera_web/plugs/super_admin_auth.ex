defmodule OmegaBraveraWeb.SuperAdminAuth do
  alias OmegaBravera.Accounts.AdminUser

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %AdminUser{role: "super"} ->
        conn

      %AdminUser{role: "partner"} ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/admin/partners")

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/")
    end
  end
end
