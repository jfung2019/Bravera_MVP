defmodule OmegaBraveraWeb.UserProfileController do
  use OmegaBraveraWeb, :controller

  alias OmegaBravera.{Money, Challenges}

  def show(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      user != nil ->
        render(
          conn,
          "show.html",
          user: user,
          num_of_activities: Challenges.get_number_of_activities_by_user(user.id),
          total_distance: Challenges.get_total_distance_by_user(user.id),
          challenges: Challenges.get_user_ngo_chals(user.id),
          num_of_supporters: get_supporters_num(user.id)
        )

      user == nil ->
        redirect(conn, to: "/404")
    end
  end

  defp get_supporters_num(user_id) do
    ids = Challenges.get_user_ngo_chals_ids(user_id)

    cond do
      Enum.empty?(ids) ->
        0

      true ->
        ids
        |> Enum.map(fn id -> Money.get_number_of_ngo_chal_sponsors(id)  end)
        |> Enum.reduce(fn id, acc -> id + acc end)
    end
  end
end
