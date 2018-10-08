defmodule OmegaBraveraWeb.AdminPanelChallengesController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges

  def index(conn, _params) do
    challenges = Challenges.list_ngo_chals_preload()
    render(conn, "index.html", challenges: challenges)
  end

  def show(conn, %{"slug" => slug}) do
    ngo_chal = Challenges.get_ngo_chal_by_slug(slug, user: [:strava], ngo: [])
    render(conn, "show.html", ngo_chal: ngo_chal)
  end
end
