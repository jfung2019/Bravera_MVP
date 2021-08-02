defmodule OmegaBraveraWeb.AdminPanelOfferVendorController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{
    Offers,
    Offers.OfferVendor
  }

  plug :assign_available_options when action in [:new, :edit]

  def index(conn, params) do
    results = Offers.paginate_offer_vendors(Guardian.Plug.current_resource(conn), params)
    render(conn, "index.html", offer_vendors: results.offer_vendors, paginate: results.paginate)
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
        conn
        |> assign_available_options(nil)
        |> render("new.html", changeset: changeset)
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
        conn
        |> assign_available_options(nil)
        |> render("edit.html", offer_vendor: offer_vendor, changeset: changeset)
    end
  end

  def assign_available_options(conn, _opts) do
    conn
    |> assign(:available_org, OmegaBravera.Accounts.list_organization_options())
  end
end
