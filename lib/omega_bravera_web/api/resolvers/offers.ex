defmodule OmegaBraveraWeb.Api.Resolvers.Offers do
  alias OmegaBravera.Offers

  def all_offers(_root, _args, %{
        context: %{current_user: %{id: user_id}}
      }) do
    {:ok, Offers.list_offers_for_user(user_id)}
  end

  def offer_offer_challenges(_root, %{offer_id: offer_id}, _info),
    do: {:ok, Offers.list_offer_offer_challenges(offer_id)}

  def get_offer(_root, %{slug: offer_slug}, _info) do
    case Offers.get_offer_by_slug(offer_slug) do
      nil ->
        {:error, message: "Offer not found"}

      offer ->
        {:ok, offer}
    end
  end
end
