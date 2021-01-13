defmodule OmegaBraveraWeb.OrgAuth do
  alias OmegaBravera.{Accounts, Accounts.PartnerUser}

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %PartnerUser{id: partner_user_id} ->
        case Plug.Conn.get_session(conn, :organization_id) do
          nil ->
            organization_member =
              Accounts.list_organization_members_by_partner_user(partner_user_id)
              |> Enum.at(0)

            conn
            |> Plug.Conn.put_session(:organization_id, organization_member.organization_id)

          _org_id ->
            conn
        end

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/")
    end
  end
end
