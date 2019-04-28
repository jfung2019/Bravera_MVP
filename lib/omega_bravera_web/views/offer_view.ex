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
    Enum.map(offer_challenges, &(&1.offer_id == offer_id && (&1.status == "active" or &1.status == "pre_registration") ))
    |> Enum.member?(true)
  end

  def has_active_offer_challenge?(_, nil), do: false

  def user_challenge_slug(%Offer{id: offer_id}, %User{offer_challenges: offer_challenges}) do
    Enum.find(offer_challenges, &(&1.offer_id == offer_id && (&1.status == "active" or &1.status == "pre_registration") ))
    |> offer_challenge_slug()
  end

  def offer_expired?(%Offer{end_date: end_date}), do: Timex.after?(Timex.now(), end_date)
  def offer_expired?(_), do: true

  defp offer_challenge_slug(%OfferChallenge{slug: slug}), do: slug
  defp offer_challenge_slug(_), do: ""
end
