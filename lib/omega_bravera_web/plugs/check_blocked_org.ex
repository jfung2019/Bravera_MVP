defmodule OmegaBraveraWeb.CheckBlockedOrg do
  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  def init(opts), do: opts

  def call(%{assigns: %{organization_id: organization_id}} = conn, _opts) do
    case OmegaBravera.Accounts.get_organization!(organization_id) do
      %{blocked_on: nil} ->
        conn
      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: Routes.org_panel_dashboard_path(conn, :blocked))
    end
  end
end