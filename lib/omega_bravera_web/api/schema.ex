defmodule OmegaBraveraWeb.Api.Schema do
  use Absinthe.Schema

  alias OmegaBraveraWeb.Api.Resolvers
  alias OmegaBraveraWeb.Schema.Types

  import_types(Types.Offer)

  query do
    @desc "Authenticate and receive an authorization token"
    field(:authenticate, non_null(:string)) do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      resolve(&Resolvers.Users.authenticate/3)
    end

    field :offer, :offer do
      arg(:id, non_null(:integer))

      resolve(fn %{id: offer_id}, _ ->
        {:ok, OmegaBravera.Offers.get_offer!(offer_id)}

      end)
    end

    field :all_offers, non_null(list_of(non_null(:offer))) do
      resolve &Resolvers.Offers.all_offers/3
    end
  end
end
