defmodule OmegaBraveraWeb.ActivityController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges

  def index(conn, %{"ngo_chal_slug" => slug, "ngo_slug" => ngo_slug}) do
    challenge = Challenges.get_ngo_chal_by_slugs(ngo_slug, slug, user: [:strava], ngo: [])
    activities = Challenges.latest_activities(challenge)
    profile_picture = get_profile_picture_link(challenge.user)

    render(conn, "index.html", %{challenge: challenge, activities: activities, profile_picture: profile_picture})
  end
end
