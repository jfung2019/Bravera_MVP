defmodule OmegaBraveraWeb.ActivityController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Challenges, Repo}

  def index(conn, %{"ngo_chal_slug" => slug}) do
    challenge = Challenges.get_ngo_chal_by_slug(slug, [user: [:strava],  ngo: []])
    activities = Challenges.latest_activities(challenge)

    render(conn, "index.html", %{challenge: challenge, activities: activities})
  end
end
