defmodule OmegaBraveraWeb.Api.Resolvers.Offers do
  alias OmegaBravera.Offers

  def all_offers(_root, _args, _info), do: {:ok, Offers.list_offers()}
  def get_offer(_root, %{id: offer_id}, %{context: %{current_user: _current_user}}), do: {:ok, Offers.get_offer!(offer_id)}
  def get_offer(_root, _args, _info), do: {:error, "not_authorized"}
end
