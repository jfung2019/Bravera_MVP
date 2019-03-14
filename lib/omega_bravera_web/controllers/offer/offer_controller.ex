defmodule OmegaBraveraWeb.Offer.OfferController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Repo, Offers, Offers.OfferChallenge}

  def index(conn, _params) do
    current_user =
      case Guardian.Plug.current_resource(conn) do
        nil -> nil
        user -> Repo.preload(user, :offer_challenges)
      end

    offers = Offers.list_offers()
    offer_challenge_changeset = Offers.change_offer_challenge(%OfferChallenge{})

    render(conn, "index.html",
      offers: offers,
      offer_challenge_changeset: offer_challenge_changeset,
      current_user: current_user
    )
  end
end
