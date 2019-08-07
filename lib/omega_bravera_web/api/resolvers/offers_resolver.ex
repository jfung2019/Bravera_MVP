defmodule OmegaBraveraWeb.Api.Resolvers.OffersResolver do
  alias OmegaBravera.Offers

  def all_offers(_root, _args, _info), do: {:ok, Offers.list_offers()}
end
