defmodule OmegaBraveraWeb.ActivityController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges

  def index(conn, %{"ngo_chal_slug" => slug, "ngo_slug" => ngo_slug}) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [], team: [:users])
    activities = Challenges.latest_activities(challenge)

    render(conn, "index.html", %{challenge: challenge, activities: activities})
  end
end
