defmodule OmegaBraveraWeb.OrgAuth do
  alias OmegaBravera.{Accounts, Accounts.PartnerUser}
  import Plug.Conn, only: [assign: 3]

  def init(opts), do: opts

  def call(conn, _opts) do
    case OmegaBravera.Guardian.Plug.current_resource(conn) do
      %PartnerUser{id: partner_user_id} = partner_user ->
        organization_ids = Accounts.list_organization_members_by_partner_user(partner_user_id)
        org_id = Plug.Conn.get_session(conn, :organization_id)

        cond do
          !is_nil(org_id) and org_id in organization_ids ->
            conn
            |> assign(:organization_id, org_id)
            |> assign(:current_partner_user, partner_user)

          true ->
            organization_id = organization_ids |> Enum.at(0)

            conn
            |> Plug.Conn.put_session(:organization_id, organization_id)
            |> assign(:organization_id, organization_id)
            |> assign(:current_partner_user, partner_user)
        end

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: "/")
    end
  end
end
