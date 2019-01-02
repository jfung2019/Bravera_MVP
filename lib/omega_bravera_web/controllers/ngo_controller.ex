defmodule OmegaBraveraWeb.NGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Fundraisers, Challenges, Challenges.NGOChal}

  def index(conn, _params) do
    ngos = Fundraisers.list_ngos()

    render(conn, "index.html", ngos: ngos)
  end

  def show(conn, %{"slug" => slug}) do
    ngo = Fundraisers.get_ngo_by_slug(slug)
    render(conn, "show.html", ngo: ngo)
  end

  def leaderboard(conn, %{"ngo_slug" => slug}) do
    ngo = Fundraisers.get_ngo_by_slug(slug)
    challenges = Challenges.get_ngo_ngo_chals(ngo) |> add_stats()

    render(conn, "leaderboard.html", %{ngo: ngo, challenges: challenges})
  end

  defp add_stats(challenges) do
    Enum.map(challenges, fn challenge ->
      challenge
      |> Map.put(:total_secured, get_total_secured(challenge))
      |> Map.put(:total_pledged, get_total_pledged(challenge))
    end)
  end

  defp get_total_secured(%NGOChal{} = challenge),
   do: get_stats(challenge) |> get_in(["total", "charged"] || 0)

  defp get_total_pledged(%NGOChal{} = challenge),
   do: get_stats(challenge) |> get_in(["total", "pending"] || 0)
end
