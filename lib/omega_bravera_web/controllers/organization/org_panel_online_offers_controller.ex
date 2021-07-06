defmodule OmegaBraveraWeb.OrgPanelOnlineOffersController do
  use OmegaBraveraWeb, :controller

  import Ecto.Query

  alias OmegaBravera.{
    Repo,
    Accounts,
    Offers,
    Offers.Offer,
    Offers.OfferChallenge
  }

  def index(conn, params) do
    results = Offers.paginate_offers("online", get_session(conn, :organization_id), params)

    render(conn, "index.html",
      offers: results.offers,
      paginate: results.paginate,
      offer_type: :online_offers,
      new_merchant: check_merchant_has_offers(conn)
    )
  end

  def show(conn, %{"slug" => slug}) do
    offer = Offers.get_offer_by_slug(slug)
    render(conn, "show.html", offer: offer)
  end

  def new(conn, _params) do
    users = Accounts.list_users()
    changeset = Offers.change_offer(%Offer{offer_type: :online})
    render(conn, "new.html", changeset: changeset, users: users)
  end

  def create(conn, %{"offer" => offer_params}) do
    offer_params = Map.put(offer_params, "organization_id", get_session(conn, :organization_id))

    case Offers.create_org_online_offer(offer_params) do
      {:ok, offer} ->
        conn
        |> put_flash(:info, "Offer created successfully.")
        |> redirect(to: Routes.live_path(conn, OmegaBraveraWeb.OrgOfferImages, offer))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
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

    case Offers.update_org_online_offer(offer, offer_params) do
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
        |> redirect(to: Routes.org_panel_online_offers_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> render("edit.html", offer: offer, changeset: changeset)
    end
  end

  def statement(%{assigns: %{organization_id: org_id}} = conn, %{"slug" => slug}) do
    now = Timex.now()

    conn
    |> put_layout({OmegaBraveraWeb.LayoutView, "print.html"})
    |> render("statement.html",
      years: (now.year - 5)..now.year,
      offer_slug: slug,
      headers: Offers.organization_statement_headers(),
      offer_redeems: Offers.list_offer_redeems_for_offer_statement_by_organization(slug, org_id)
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

  defp check_merchant_has_offers(%{assigns: %{organization: %{id: org_id, account_type: :merchant}}}) do
    case Offers.list_offers_by_organization(org_id) do
      [] -> true
      _ ->  false
    end
  end

  defp check_merchant_has_offers(_conn), do: nil
end
