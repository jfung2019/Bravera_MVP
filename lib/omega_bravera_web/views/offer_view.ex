defmodule OmegaBraveraWeb.Offer.OfferView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{Accounts.User, Offers.Offer, Offers.OfferChallenge}

  def team_enabled_ngo?(%Offer{additional_members: additional_members})
      when additional_members > 0,
      do: true

  def team_enabled_ngo?(%Offer{additional_members: additional_members})
      when additional_members <= 0,
      do: false

  def user_full_name(%User{} = user), do: User.full_name(user)

  def has_active_offer_challenge?(%Offer{id: offer_id}, %User{offer_challenges: offer_challenges}) do
    Enum.map(
      offer_challenges,
      &(&1.offer_id == offer_id && (&1.status == "active" or &1.status == "pre_registration"))
    )
    |> Enum.member?(true)
  end

  def has_active_offer_challenge?(_, nil), do: false

  def user_challenge_slug(%Offer{id: offer_id}, %User{offer_challenges: offer_challenges}) do
    Enum.find(
      offer_challenges,
      &(&1.offer_id == offer_id && (&1.status == "active" or &1.status == "pre_registration"))
    )
    |> offer_challenge_slug()
  end

  def offer_expired?(%Offer{end_date: end_date}), do: Timex.after?(Timex.now(), end_date)
  def offer_expired?(_), do: true

  defp offer_challenge_slug(%OfferChallenge{slug: slug}), do: slug
  defp offer_challenge_slug(_), do: ""

  def payment_offer?(nil), do: false
  def payment_offer?(payment_amount), do: Decimal.cmp(payment_amount, Decimal.new(0)) == :gt

  def generate_offer_challenge_link(conn, nil, offer),
    do:
      link(gettext("Join the challenge"),
        to: Routes.offer_offer_challenge_path(conn, :new, offer),
        class: "btn btn-green sign-up text-capitalize"
      )

  # TODO: support expired and pre_registration challenges. -Sherief
  def generate_offer_challenge_link(conn, %{offer_challenges: chals}, %{id: id} = offer) do
    case Enum.find(chals, fn %{offer_id: offer_id} -> offer_id == id end) do
      nil ->
        generate_offer_challenge_link(conn, nil, offer)

      challenge ->
        redeemed_found = Enum.find(challenge.offer_redeems, &(&1.status == "redeemed"))

        cond do
          challenge.status == "complete" and is_nil(redeemed_found) ->
            link(gettext("Get Reward"),
              to: Routes.offer_offer_challenge_path(conn, :show, offer, challenge),
              class: "btn btn-bravera sign-up text-capitalize"
            )

          challenge.status == "pre_registration" or challenge.status == "active" ->
            link(gettext("View your progress"),
              to: Routes.offer_offer_challenge_path(conn, :show, offer, challenge),
              class: "btn btn-bravera sign-up text-capitalize"
            )

          true ->
            generate_offer_challenge_link(conn, nil, offer)
        end
    end
  end

  def generate_team_member_offer_challenge_link(_conn, nil, _offer), do: ""

  def generate_team_member_offer_challenge_link(conn, %User{offer_teams: offer_teams}, offer)
      when length(offer_teams) > 0 do
    team_challenges = Enum.filter(offer_teams, &(offer.id == &1.offer_challenge.offer_id))

    if not Enum.empty?(team_challenges) do
      oldest_team = Enum.min_by(team_challenges, & &1.offer_challenge.id)
      generate_team_member_link(conn, oldest_team.offer_challenge, offer)
    end
  end

  def generate_team_member_offer_challenge_link(_conn, _, _offer), do: ""

  defp generate_team_member_link(conn, challenge, offer) do
    cond do
      challenge.status == "complete" ->
        link(gettext("Get Team's Reward"),
          to: Routes.offer_offer_challenge_path(conn, :show, offer, challenge),
          class: "btn btn-bravera sign-up text-capitalize"
        )

      challenge.status == "pre_registration" or challenge.status == "active" ->
        link(gettext("View your Team's progress"),
          to: Routes.offer_offer_challenge_path(conn, :show, offer, challenge),
          class: "btn btn-bravera sign-up text-capitalize"
        )

      true ->
        ""
    end
  end
end
