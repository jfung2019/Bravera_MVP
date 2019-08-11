defmodule OmegaBraveraWeb.Api.Schema do
  use Absinthe.Schema

  alias OmegaBraveraWeb.Api.Resolvers
  alias OmegaBraveraWeb.Api.Types

  import_types(Types.Offer)
  import_types(Types.OfferChallenge)
  import_types(Types.Account)
  import_types(Types.Helpers)

  mutation do
    @desc "Authenticate and receive an authorization token and a user."
    field :login, :user_session_result do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      resolve &Resolvers.Accounts.login/3
    end

    @desc "Sign a user up."
    field :create_user, :user_signup_result do
      arg :input, non_null(:user_signup_input)
      resolve &Resolvers.Accounts.create_user/3
    end

    @desc "Create offer challenge."
    field :create_offer_challenge, :offer_challenge_create_result do
      arg :input, non_null(:offer_challenge_create_input)
      resolve &Resolvers.OfferChallenges.create/3
    end
  end

  query do
    @desc "Get a single offer by ID"
    field :offer, :offer do
      arg :id, non_null(:integer)
      resolve &Resolvers.Offers.get_offer/3
    end

    @desc "Get a list of all offers"
    field :all_offers, list_of(non_null(:offer)) do
      resolve &Resolvers.Offers.all_offers/3
    end
  end
end
