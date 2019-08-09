defmodule OmegaBraveraWeb.Api.Schema do
  use Absinthe.Schema

  alias OmegaBraveraWeb.Api.Resolvers
  alias OmegaBraveraWeb.Schema.Types

  import_types(Types.Offer)
  import_types(Types.Account)

  mutation do
    @desc "Authenticate and receive an authorization token and a user."
    field :login, :user_session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      resolve &Resolvers.Accounts.login/3
    end
  end

  query do
    @desc "Get a single offer by ID"
    field :offer, :offer do
      arg(:id, non_null(:integer))
      resolve &Resolvers.Offers.get_offer/3
    end

    @desc "Get a list of all offers"
    field :all_offers, list_of(non_null(:offer)) do
      resolve &Resolvers.Offers.all_offers/3
    end
  end
end
