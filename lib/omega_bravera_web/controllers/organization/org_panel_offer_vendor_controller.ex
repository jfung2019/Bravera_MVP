defmodule OmegaBraveraWeb.OrgPanelOfferVendorController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{
    Offers,
    Offers.OfferVendor
  }

  def index(%{assigns: %{organization_id: org_id}} = conn, params) do
    results = Offers.paginate_offer_vendors(get_session(conn, :organization_id), params)

    first_vendor = Offers.created_first_vendor?(org_id)

    render(conn, "index.html",
      offer_vendors: results.offer_vendors,
      paginate: results.paginate,
      first_vendor: first_vendor
    )
  end

  def new(conn, _params) do
    changeset = Offers.change_offer_vendor(%OfferVendor{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"offer_vendor" => offer_vendor_params}) do
    offer_vendor_params =
      Map.put(offer_vendor_params, "organization_id", get_session(conn, :organization_id))

    case Offers.create_org_offer_vendor(offer_vendor_params) do
      {:ok, _offer_vendor} ->
        conn
        |> put_flash(:info, "Claim ID created successfully.")
        |> redirect(to: Routes.org_panel_offer_vendor_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}),
    do: render(conn, "show.html", offer_vendor: Offers.get_offer_vendor!(id, [:offers]))

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
        |> put_flash(:info, "Claim ID updated successfully.")
        |> redirect(to: Routes.org_panel_offer_vendor_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", offer_vendor: offer_vendor, changeset: changeset)
    end
  end
end
