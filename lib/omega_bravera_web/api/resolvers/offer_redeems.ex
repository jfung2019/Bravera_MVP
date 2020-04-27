defmodule OmegaBraveraWeb.Api.Resolvers.OfferRedeems do
  alias OmegaBravera.Offers

  def latest_expired_redeems(_root, _args, %{context: %{current_user: %{id: user_id}}}),
    do: {:ok, Offers.list_expired_offer_redeems(user_id)}
end
