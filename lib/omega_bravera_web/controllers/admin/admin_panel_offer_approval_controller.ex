defmodule OmegaBraveraWeb.AdminPanelOfferApprovalController do
  use OmegaBraveraWeb, :controller
  alias OmegaBravera.{Offers, Offers.OfferApproval}

  def show(conn, %{"slug" => slug}) do
    render(conn, "show.html",
      offer: Offers.get_offer_by_slug(slug, [:vendor, :offer_rewards, :organization, :location]),
      changeset: Offers.change_offer_approval(%OfferApproval{})
    )
  end

  def create(conn, %{"offer_approval" => %{"offer_id" => id} = approval_param}) do
    case Offers.create_offer_approval(approval_param) do
      {:ok, %{changes: %{status: status}}} ->
        conn
        |> put_flash(:info, "Offer #{status}.")
        |> redirect(to: Routes.admin_panel_offer_path(conn, :index))

      {:error, changeset} ->
        render(conn, "show.html",
          offer: Offers.get_offer!(id, [:vendor, :offer_rewards, :organization, :location]),
          changeset: changeset
        )
    end
  end
end
