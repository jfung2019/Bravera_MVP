defmodule OmegaBraveraWeb.AdminPanelOfferController do
  use OmegaBraveraWeb, :controller

  import Ecto.Query

  alias OmegaBravera.{
    Repo,
    Accounts,
    Offers,
    Offers.Offer,
    Fundraisers.NgoOptions,
    Offers.OfferChallenge
  }

  use Timex

  plug(:assign_available_options when action in [:edit, :new])

  def index(conn, _params) do
    offers =
      Offers.list_offers_preload([:vendor, :offer_challenges, offer_redeems: [:offer_reward]])

    render(conn, "index.html", offers: offers)
  end

  def show(conn, %{"slug" => slug}) do
    offer = Offers.get_offer_by_slug(slug)
    render(conn, "show.html", offer: offer)
  end

  def new(conn, _params) do
    users = Accounts.list_users()
    vendors = Offers.list_offer_vendors()
    changeset = Offers.change_offer(%Offer{})
    render(conn, "new.html", changeset: changeset, users: users, vendors: vendors)
  end

  def create(conn, %{"offer" => offer_params}) do
    case Offers.create_offer(offer_params) do
      {:ok, offer} ->
        conn
        |> put_flash(:info, "Offer created successfully.")
        |> redirect(to: Routes.admin_panel_offer_path(conn, :show, offer))

      {:error, %Ecto.Changeset{} = changeset} ->
        vendors = Offers.list_offer_vendors()

        conn
        |> assign_available_options(nil)
        |> render("new.html", changeset: changeset, vendors: vendors)
    end
  end

  def edit(conn, %{"slug" => slug}) do
    offer = Offers.get_offer_by_slug_with_hk_time(slug)
    vendors = Offers.list_offer_vendors()
    changeset = Offers.change_offer(offer)

    render(conn, "edit.html", offer: offer, vendors: vendors, changeset: changeset)
  end

  def update(conn, %{"slug" => slug, "offer" => offer_params}) do
    offer = Offers.get_offer_by_slug_with_hk_time(slug)

    case Offers.update_offer(offer, offer_params) do
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
        |> redirect(to: Routes.admin_panel_offer_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        vendors = Offers.list_offer_vendors()

        conn
        |> assign_available_options(nil)
        |> render("edit.html", offer: offer, vendors: vendors, changeset: changeset)
    end
  end

  def statement(conn, %{"slug" => slug}) do
    render(conn, "statement.html",
      offer_slug: slug,
      offer_redeems:
        Offers.list_offer_redeems_for_offer_statement(slug, [
          :offer_challenge,
          :user,
          :offer_reward
        ]),
      layout: {OmegaBraveraWeb.LayoutView, "print.html"}
    )
  end

  def export_statement(conn, %{"slug" => slug, "month" => month, "year" => year}) do
    {:ok, start_date} = Date.new(String.to_integer(year), String.to_integer(month), 1)
    start_datetime = Timex.to_datetime(start_date)
    end_datetime = Timex.shift(start_datetime, months: 1)
    csv_rows = Offers.get_monthly_statement_for_offer(slug, start_datetime, end_datetime)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{slug}'s_statement_for_#{month}.csv\""
    )
    |> send_resp(200, to_csv(csv_statement_headers(), csv_rows))
  end

  def to_csv(cols, rows) do
    (cols ++ rows)
    |> CSV.encode()
    |> Enum.to_list()
    |> to_string
  end

  defp csv_statement_headers() do
    [
      [
        "Slug",
        "Firstname",
        "Lastname",
        "Email",
        "Challenge Creation",
        "Challenge Completed Date",
        "Team",
        "Redeemed Date",
        "Name"
      ]
    ]
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_currencies, NgoOptions.currency_options_human())
    |> assign(:available_activities, NgoOptions.activity_options())
    |> assign(:available_challenge_type_options, NgoOptions.challenge_type_options_human())
    |> assign(:available_locations, OmegaBravera.Locations.list_locations())
    |> assign(:available_partners, OmegaBravera.Partners.partner_options())
    |> assign(:available_offer_types, [{"In Store", "in_store"},{"Online", "online"}])
  end
end
