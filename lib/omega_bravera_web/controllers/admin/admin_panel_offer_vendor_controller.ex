defmodule OmegaBraveraWeb.AdminPanelOfferVendorController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Offers
  alias OmegaBravera.Offers.OfferVendor

  def index(conn, _params) do
    offer_vendors = Offers.list_offer_vendors()
    render(conn, "index.html", offer_vendors: offer_vendors)
  end

  def new(conn, _params) do
    changeset = Offers.change_offer_vendor(%OfferVendor{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"offer_vendor" => offer_vendor_params}) do
    case Offers.create_offer_vendor(offer_vendor_params) do
      {:ok, _offer_vendor} ->
        conn
        |> put_flash(:info, "Offer vendor created successfully.")
        |> redirect(to: Routes.admin_panel_offer_vendor_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    offer_vendor = Offers.get_offer_vendor!(id)
    changeset = Offers.change_offer_vendor(offer_vendor)
    render(conn, "edit.html", offer_vendor: offer_vendor, changeset: changeset)
  end

  def update(conn, %{"id" => id, "offer_vendor" => offer_vendor_params}) do
    offer_vendor = Offers.get_offer_vendor!(id)

    case Offers.update_offer_vendor(offer_vendor, offer_vendor_params) do
      {:ok, _offer_vendor} ->
        conn
        |> put_flash(:info, "Offer vendor updated successfully.")
        |> redirect(to: Routes.admin_panel_offer_vendor_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", offer_vendor: offer_vendor, changeset: changeset)
    end
  end
end
