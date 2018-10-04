defmodule OmegaBraveraWeb.AdminPanelChallengesController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.Challenges

  def index(conn, _params) do
    challenges = Challenges.list_ngo_chals_preload()
    render(conn, "index.html", challenges: challenges)
  end
end
