defmodule OmegaBraveraWeb.OrgAuth do
  alias OmegaBravera.Accounts.PartnerUser
  alias OmegaBraveraWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %PartnerUser{} ->
        conn

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/")
    end
  end
end
