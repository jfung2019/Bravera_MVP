defmodule OmegaBraveraWeb.Offer.OfferController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Offers, Offers.OfferChallenge, Accounts, Accounts.AdminUser}

  def index(conn, _params) do
    current_user =
      case Guardian.Plug.current_resource(conn) do
        nil ->
          nil

        %AdminUser{} ->
          redirect(conn, to: Routes.admin_user_page_path(conn, :index))

        user ->
          Accounts.preload_active_offer_challenges(user)
      end

    conn
    |> open_modal(:could_not_create_offer_challenge)
    |> render("index.html",
      offers:
        Offers.list_offers(false, offer_challenges: [user: [:strava], team: [users: [:strava]]]),
      offer_challenge_changeset: Offers.change_offer_challenge(%OfferChallenge{}),
      current_user: current_user
    )
  end
end
