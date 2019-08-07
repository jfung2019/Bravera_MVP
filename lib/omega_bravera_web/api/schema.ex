defmodule OmegaBraveraWeb.Api.Schema do
  use Absinthe.Schema

  alias OmegaBravera.Offers
  alias OmegaBraveraWeb.Api.Resolvers.OffersResolver

  object :offer do
    field(:id, non_null(:integer))
    field(:name, non_null(:string))
  end

  query do
    field :offer, :offer do
      arg(:id, non_null(:integer))

      resolve(fn %{id: offer_id}, _ ->
        {:ok, Offers.get_offer!(offer_id)}

      end)
    end

    field :all_offers, non_null(list_of(non_null(:offer))) do
      resolve &OffersResolver.all_offers/3
    end
  end
end
