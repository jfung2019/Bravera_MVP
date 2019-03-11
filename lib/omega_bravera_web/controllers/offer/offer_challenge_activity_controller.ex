defmodule OmegaBraveraWeb.Offer.OfferChallengeActivityController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Offers

  def index(conn, %{"offer_challenge_slug" => slug, "offer_slug" => offer_slug}) do
    challenge =
      Offers.get_offer_chal_by_slugs(offer_slug, slug, user: [:strava], offer: [])

    activities = Offers.latest_activities(challenge)

    render(conn, "index.html", %{challenge: challenge, activities: activities})
  end
end
