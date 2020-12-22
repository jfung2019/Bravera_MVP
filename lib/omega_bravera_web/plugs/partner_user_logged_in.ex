defmodule OmegaBraveraWeb.PartnerUserLoggedIn do
  alias OmegaBravera.Accounts.PartnerUser
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %PartnerUser{} = partner_user ->
        Plug.Conn.assign(conn, :partner_user, partner_user)

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/")
    end
  end
end
