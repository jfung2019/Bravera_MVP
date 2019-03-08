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
    Enum.map(offer_challenges, &(&1.id))
    |> Enum.member?(id)
  end

  def user_joined_offer_before?(_, nil), do: false
end
