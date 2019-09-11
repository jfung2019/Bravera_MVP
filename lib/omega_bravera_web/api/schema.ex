defmodule OmegaBraveraWeb.Api.Schema do
  use Absinthe.Schema

  alias OmegaBraveraWeb.Api.{Resolvers, Types, Middleware}

  import_types(Types.Offer)
  import_types(Types.OfferChallenge)
  import_types(Types.Account)
  import_types(Types.Device)
  import_types(Types.Helpers)

  mutation do
    @desc "Register a new user device."
    field :register_device, :register_device_result do
      arg(:input, non_null(:register_device_input))
      middleware Middleware.Authenticate
      resolve(&Resolvers.Devices.register_device/3)
    end

    @desc "Authenticate and receive an authorization token and a user."
    field :login, :user_session_result do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:locale, non_null(:string))
      resolve(&Resolvers.Accounts.login/3)
    end

    @desc "Sign a user up."
    field :create_user, :user_signup_result do
      arg(:input, non_null(:user_signup_input))
      resolve(&Resolvers.Accounts.create_user/3)
    end

    @desc "Create offer challenge."
    field :create_offer_challenge, :offer_challenge_create_result do
      arg(:input, non_null(:offer_challenge_create_input))
      middleware Middleware.Authenticate
      resolve(&Resolvers.OfferChallenges.create/3)
    end
  end

  query do
    @desc "Get a single offer by ID"
    field :offer, :offer do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Offers.get_offer/3)
    end

    @desc "Get a list of all offers"
    field :all_offers, list_of(non_null(:offer)) do
      resolve(&Resolvers.Offers.all_offers/3)
    end

    @desc "Get a list of all locations"
    field :all_locations, list_of(non_null(:location)) do
      resolve(&Resolvers.Accounts.all_locations/3)
    end

    @desc "Get logged in user profile"
    field :user_profile, :user_profile do
      middleware Middleware.Authenticate
      resolve(&Resolvers.Accounts.user_profile/3)
    end
  end
end
