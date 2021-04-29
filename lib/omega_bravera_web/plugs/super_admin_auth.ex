defmodule OmegaBraveraWeb.SuperAdminAuth do
  alias OmegaBravera.{Accounts.AdminUser, Accounts}
  alias OmegaBraveraWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %AdminUser{role: "super"} ->
        view_as_org_id = Plug.Conn.get_session(conn, :view_as_org_id)

        case Accounts.get_organization(view_as_org_id) do
          %{id: ^view_as_org_id} = view_as_org ->
            conn
            |> Plug.Conn.assign(:view_as_org, view_as_org)

          _ ->
            conn
        end

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
