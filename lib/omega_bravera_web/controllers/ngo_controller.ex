defmodule OmegaBraveraWeb.NGOController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Fundraisers, Challenges, Challenges.NGOChal, Accounts.AdminUser}

  def index(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      %AdminUser{} ->
        redirect(conn, to: Routes.admin_user_page_path(conn, :index))

      _ ->
        render(conn, "index.html",
          ngos:
            Fundraisers.list_ngos(false, ngo_chals: [user: [:strava], team: [users: [:strava]]])
        )
    end
  end

  def show(conn, %{"slug" => slug}) do
    case Fundraisers.get_ngo_by_slug(slug) do
      nil ->
        conn
        |> put_view(OmegaBraveraWeb.PageView)
        |> put_status(:not_found)
        |> render("404.html", layout: {OmegaBraveraWeb.LayoutView, "no-nav.html"})

      ngo ->
        render(conn, "show.html", ngo: ngo)
    end
  end

  def leaderboard(conn, %{"ngo_slug" => slug}) do
    ngo = Fundraisers.get_ngo_by_slug(slug)

    milestone_challenges_task =
      Task.async(fn ->
        Challenges.get_ngo_milestone_ngo_chals(ngo)
        |> add_stats()
        |> order_by_total_secured()
      end)

    km_challenges_task =
      Task.async(fn ->
        Challenges.get_ngo_km_ngo_chals(ngo)
        |> add_stats()
        |> order_by_total_secured()
      end)

    milestone_challenges = Task.await(milestone_challenges_task, 25000)
    km_challenges = Task.await(km_challenges_task, 25000)

    render(conn, "leaderboard.html", %{
      ngo: ngo,
      milestone_challenges: milestone_challenges,
      km_challenges: km_challenges
    })
  end

  defp add_stats(challenges) do
    Enum.map(challenges, fn challenge ->
      case challenge.type do
        "PER_KM" ->
          {total_per_km_pledges, follow_on_donations} =
            Challenges.get_per_km_challenge_total_pledges(challenge.slug)

          total_support =
            total_per_km_pledges
            |> Decimal.mult(Decimal.new(challenge.distance_target))
            |> Decimal.round(1)
            |> Decimal.add(follow_on_donations)

          current_distance_value = get_total_secured(challenge)

          secured =
            cond do
              Decimal.cmp(current_distance_value, total_support) == :gt -> total_support
              Decimal.cmp(current_distance_value, total_support) == :lt -> current_distance_value
              true -> total_support
            end

          challenge
          |> Map.put(:total_secured, secured)
          |> Map.put(:total_pledged, get_total_pledged(challenge))

        "PER_MILESTONE" ->
          challenge
          |> Map.put(:total_secured, get_total_secured(challenge))
          |> Map.put(:total_pledged, get_total_pledged(challenge))
      end
    end)
  end

  defp get_total_secured(%NGOChal{type: "PER_MILESTONE"} = challenge),
    do: get_stats(challenge) |> get_in(["total", "charged"]) || 0

  defp get_total_secured(%NGOChal{type: "PER_KM"} = challenge) do
    challenge = Challenges.get_ngo_chal!(challenge.id)

    {total_per_km_pledges, follow_on_donations} =
      Challenges.get_per_km_challenge_total_pledges(challenge.slug)

    Decimal.mult(
      total_per_km_pledges,
      challenge.distance_covered
    )
    |> Decimal.round(1)
    |> Decimal.add(follow_on_donations)
  end

  defp get_total_pledged(%NGOChal{} = challenge),
    do: get_stats(challenge) |> get_in(["total", "pending"]) || 0

  defp order_by_total_secured(chals),
    do: Enum.sort(chals, &(&1.total_secured >= &2.total_secured))
end
