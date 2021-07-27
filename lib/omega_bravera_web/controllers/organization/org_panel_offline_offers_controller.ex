defmodule OmegaBraveraWeb.OrgPanelOfflineOffersController do
  use OmegaBraveraWeb, :controller

  import Ecto.Query

  alias OmegaBravera.{
    Repo,
    Accounts,
    Offers,
    Offers.Offer,
    Offers.OfferChallenge
  }

  use Timex

  plug :assign_available_options when action in [:edit, :new]

  def index(%{assigns: %{organization_id: org_id}} = conn, params) do
    results = Offers.paginate_offers("in_store", org_id, params)

    render(conn, "index.html",
      offers: results.offers,
      paginate: results.paginate
    )
  end

  def show(%{assigns: %{organization_id: org_id}} = conn, %{"slug" => slug}) do
    %{organization_id: ^org_id} = offer = Offers.get_offer_by_slug(slug)
    render(conn, "show.html", offer: offer)
  end

  def new(conn, _params) do
    users = Accounts.list_users()
    changeset = Offers.change_offer(%Offer{offer_type: :in_store})
    render(conn, "new.html", changeset: changeset, users: users)
  end

  def create(%{assigns: %{organization_id: org_id}} = conn, %{"offer" => offer_params}) do
    case Offers.create_org_offline_offer(Map.put(offer_params, "organization_id", org_id)) do
      {:ok, offer} ->
        conn
        |> put_flash(:info, "Offer created successfully.")
        |> redirect(to: Routes.live_path(conn, OmegaBraveraWeb.OrgOfferImages, offer))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign_available_options(nil)
        |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"slug" => slug}) do
    offer = Offers.get_offer_by_slug_for_panel(slug)
    changeset = Offers.change_offer(offer)

    render(conn, "edit.html", offer: offer, changeset: changeset)
  end

  def update(conn, %{"slug" => slug, "offer" => offer_params}) do
    offer = Offers.get_offer_by_slug_for_panel(slug)

    case Offers.update_org_offline_offer(offer, offer_params) do
      {:ok, updated_offer} ->
        # Update all pre_registration challenges' start date
        updated_offer = Offers.get_offer_by_slug(updated_offer.slug)

        Repo.update_all(
          from(
            offer_challenge in OfferChallenge,
            where:
              offer_challenge.offer_id == ^updated_offer.id and
                offer_challenge.status == "pre_registration"
          ),
          set: [start_date: updated_offer.start_date, end_date: updated_offer.end_date]
        )

        if(hd(offer.offer_challenge_types) == "BRAVERA_SEGMENT") do
          Repo.update_all(
            from(
              offer_challenge in OfferChallenge,
              where:
                (offer_challenge.offer_id == ^updated_offer.id and
                   offer_challenge.status == "active") or
                  offer_challenge.status == "pre_registration"
            ),
            set: [distance_target: updated_offer.target]
          )
        end

        conn
        |> put_flash(:info, "Offer updated successfully.")
        |> redirect(to: Routes.org_panel_offline_offers_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign_available_options(nil)
        |> render("edit.html", offer: offer, changeset: changeset)
    end
  end

  def statement(%{assigns: %{organization: org}} = conn, %{"slug" => slug}) do
    now = Timex.now()

    conn
    |> put_layout({OmegaBraveraWeb.LayoutView, "print.html"})
    |> render("statement.html",
      years: (now.year - 5)..now.year,
      offer_slug: slug,
      headers: Offers.organization_statement_headers(org),
      offer_redeems: Offers.list_offer_redeems_for_offer_statement_by_organization(slug, org.id)
    )
  end

  def export_statement(%{assigns: %{organization_id: org_id}} = conn, %{
        "slug" => slug,
        "month" => month,
        "year" => year
      }) do
    csv = Offers.get_monthly_statement_for_organization_offer(slug, org_id, month, year)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{slug}'s_statement_for_#{month}.csv\""
    )
    |> send_resp(200, csv)
  end

  defp assign_available_options(%{assigns: %{organization_id: org_id}} = conn, _opts) do
    conn
    |> assign(:available_locations, OmegaBravera.Locations.list_locations())
    |> assign(
      :vendors,
      Offers.list_offer_vendors_by_organization(org_id)
    )
  end
end
