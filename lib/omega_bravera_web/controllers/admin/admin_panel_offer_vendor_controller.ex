defmodule OmegaBraveraWeb.AdminPanelOfferVendorController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{
    Offers,
    Offers.OfferVendor
  }

  def index(conn, params) do
    results = check_view_as(conn, params)
    render(conn, "index.html", offer_vendors: results.offer_vendors, paginate: results.paginate)
  end

  defp check_view_as(%{assigns: %{view_as_org: %{id: org_id}}}, params),
    do: Offers.paginate_offer_vendors(org_id, params)

  defp check_view_as(conn, params),
    do: Offers.paginate_offer_vendors(Guardian.Plug.current_resource(conn), params)

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
        |> put_flash(:info, "Offer vendor updated successfully.")
        |> redirect(to: Routes.admin_panel_offer_vendor_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", offer_vendor: offer_vendor, changeset: changeset)
    end
  end
end
