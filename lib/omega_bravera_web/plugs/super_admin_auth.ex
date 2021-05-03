defmodule OmegaBraveraWeb.SuperAdminAuth do
  alias OmegaBravera.{Accounts.AdminUser, Accounts}
  alias OmegaBraveraWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %AdminUser{role: "super"} ->
        conn

      %AdminUser{role: "partner"} ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(
          to: Routes.admin_panel_partner_path(OmegaBraveraWeb.Endpoint, :index)
        )

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/")
    end
  end
end
