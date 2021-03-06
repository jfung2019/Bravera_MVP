defmodule OmegaBraveraWeb.AdminPanelOfferPartnerController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Groups

  def create(conn, %{"partner_id" => partner_id} = params) do
    case Groups.create_offer_partner(params) do
      {:ok, _} ->
        conn
        |> redirect(to: Routes.admin_panel_partner_path(conn, :show, partner_id))
    end
  end

  def delete(conn, %{"id" => offer_partner_id}) do
    %{partner_id: partner_id} = offer_partner = Groups.get_offer_partner!(offer_partner_id)
    Groups.delete_offer_partner(offer_partner)
    redirect(conn, to: Routes.admin_panel_partner_path(conn, :show, partner_id))
  end
end
