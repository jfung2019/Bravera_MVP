defmodule OmegaBraveraWeb.Api.Resolvers.Offers do
  alias OmegaBravera.Offers

  def all_offers(_root, _args, _info), do: {:ok, Offers.list_offers()}

  def offer_offer_challenges(_root, %{offer_id: offer_id}, _info),
    do: {:ok, Offers.list_offer_offer_challenges(offer_id)}

  def get_offer(_root, %{id: offer_id}, %{context: %{current_user: _current_user}}),
    do: {:ok, Offers.get_offer!(offer_id)}

  def get_offer(_root, _args, _info), do: {:error, "not_authorized"}
end
