defmodule OmegaBraveraWeb.AdminPanelOfferController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Accounts, Offers, Offers.Offer, Fundraisers.NgoOptions}

  use Timex

  plug(:assign_available_options when action in [:edit, :new])

  def index(conn, _params) do
    offers = Offers.list_offers_preload([:vendor, offer_redeems: [:offer_reward]])
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
        |> redirect(to: admin_panel_offer_path(conn, :show, offer))

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
        # Update all pre_registration challenges' start date and end_dates
        offer.offer_challenges
        |> Enum.map(fn offer_challenge ->
          cond do
            offer_challenge.status == "pre_registration" ->
              Offers.update_offer_challenge(offer_challenge, %{
                start_date: updated_offer.launch_date,
                end_date: updated_offer.end_date
              })

            offer_challenge.status == "active" ->
              Offers.update_offer_challenge(offer_challenge, %{
                start_date: updated_offer.start_date,
                end_date: updated_offer.end_date
              })

            true ->
              nil
          end
        end)

        conn
        |> put_flash(:info, "Offer updated successfully.")
        |> redirect(to: admin_panel_offer_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        vendors = Offers.list_offer_vendors()

        conn
        |> assign_available_options(nil)
        |> render("edit.html", offer: offer, vendors: vendors, changeset: changeset)
    end
  end

  defp assign_available_options(conn, _opts) do
    conn
    |> assign(:available_currencies, NgoOptions.currency_options_human())
    |> assign(:available_activities, NgoOptions.activity_options())
    |> assign(:available_distances, NgoOptions.distance_options())
    |> assign(:available_challenge_type_options, NgoOptions.challenge_type_options_human())
  end
end
