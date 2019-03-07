defmodule OmegaBraveraWeb.Offer.OfferController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Offers, Offers.OfferChallenge}

  def index(conn, _params) do
    offers = Offers.list_offers()
    offer_challenge_changeset = Offers.change_offer_challenge(%OfferChallenge{})
    render(conn, "index.html", offers: offers, offer_challenge_changeset: offer_challenge_changeset)
  end
end
