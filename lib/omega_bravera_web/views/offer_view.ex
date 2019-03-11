defmodule OmegaBraveraWeb.Offer.OfferView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.{Accounts.User, Offers.Offer}

  def team_enabled_ngo?(%Offer{additional_members: additional_members})
      when additional_members > 0,
      do: true

  def team_enabled_ngo?(%Offer{additional_members: additional_members})
      when additional_members <= 0,
      do: false

  def user_full_name(%User{} = user), do: User.full_name(user)

  def user_joined_offer_before?(%Offer{id: id}, %User{offer_challenges: offer_challenges}) do
    Enum.map(offer_challenges, &(&1.offer_id))
    |> Enum.member?(id)
  end

  def user_joined_offer_before?(_, nil), do: false

  def user_challenge_slug(%Offer{id: id}, %User{offer_challenges: offer_challenges}) do
    user_challenge_slug(id, offer_challenges)
  end

  def user_challenge_slug(id, [hd | tail]) do
    if id == hd.offer_id do
      hd.slug
    else
      user_challenge_slug(id, tail)
    end
  end
end
