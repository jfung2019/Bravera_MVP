defmodule OmegaBraveraWeb.Offer.OfferController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Repo, Offers, Offers.OfferChallenge, Accounts.AdminUser}

  def index(conn, _params) do
    current_user =
      case Guardian.Plug.current_resource(conn) do
        nil ->
          nil

        %AdminUser{} ->
          redirect(conn, to: admin_user_page_path(conn, :index))

        user ->
          Repo.preload(user, :offer_challenges)
      end

    offers = Offers.list_offers(false, [offer_challenges: [user: [:strava], team: [users: [:strava]]]])
    offer_challenge_changeset = Offers.change_offer_challenge(%OfferChallenge{})

    render(conn, "index.html",
      offers: offers,
      offer_challenge_changeset: offer_challenge_changeset,
      current_user: current_user
    )
  end
end
