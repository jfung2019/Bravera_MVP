defmodule OmegaBraveraWeb.OrgPanelOfferPartnerController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.Groups

  def create(conn, %{"partner_id" => partner_id} = params) do
    case Groups.create_org_offer_partner(params) do
      {:ok, %{partner_id: partner_id}} ->
        conn
        |> redirect(to: Routes.org_panel_partner_path(conn, :show, partner_id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to add offer to group")
        |> redirect(to: Routes.org_panel_partner_path(conn, :show, partner_id))
    end
  end

  def delete(conn, %{"id" => offer_partner_id}) do
    %{partner_id: partner_id} = offer_partner = Groups.get_offer_partner!(offer_partner_id)
    Groups.delete_offer_partner(offer_partner)
    redirect(conn, to: Routes.org_panel_partner_path(conn, :show, partner_id))
  end

  def approval(conn, %{"id" => offer_partner_id}) do
    %{partner_id: partner_id, offer_id: offer_id} = Groups.get_offer_partner!(offer_partner_id)

    case Groups.resubmit_offer_partner_for_approval(offer_id) do
      :ok ->
        conn
        |> put_flash(:info, "The offer has been successfully been resubmitted for approval")
        |> redirect(to: Routes.org_panel_partner_path(conn, :show, partner_id))

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to resubmit offer for approval")
        |> redirect(to: Routes.org_panel_partner_path(conn, :show, partner_id))
    end
  end
end
