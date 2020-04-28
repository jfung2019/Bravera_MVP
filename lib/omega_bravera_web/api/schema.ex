defmodule OmegaBraveraWeb.Api.Schema do
  use Absinthe.Schema
  alias OmegaBraveraWeb.Api.{Resolvers, Types, Middleware}

  import_types Types.Offer
  import_types Types.OfferChallenge
  import_types Types.Account
  import_types Types.Device
  import_types Types.Activity
  import_types Types.Referral
  import_types Types.Reward
  import_types Types.Redeem
  import_types Types.Point
  import_types Types.Helpers
  import_types Types.Partners

  mutation do
    @desc "Set profile picture"
    field :set_profile_picture, :user do
      arg :picture_url, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.profile_picture_update/3
    end

    @desc "Delete user profile picture and strava profile picture"
    field :delete_user_profile_picture, :delete_profile_picture_result do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.delete_user_pictures/3
    end

    @desc "Forgot password: change password"
    field :forgot_password_change_password, :forgot_password_change_password_result do
      arg :reset_token, non_null(:string)
      arg :password, non_null(:string)
      arg :password_confirm, non_null(:string)
      resolve &Resolvers.Accounts.forgot_password_change_password/3
    end

    @desc "Send reset password code"
    field :send_reset_password_code, :send_reset_password_code_result do
      arg :email, non_null(:string)
      resolve &Resolvers.Accounts.send_reset_password_code/3
    end

    @desc "Save User Settings"
    field :save_user_settings, :user do
      arg :input, non_null(:user_settings_input)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.save_settings/3
    end

    @desc "Buy an offer using points"
    field :buy_offer_challenge, :buy_or_create_offer_challenge_result do
      arg :offer_slug, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.OfferChallenges.buy/3
    end

    @desc "Create a challenge"
    field :earn_offer_challenge, :buy_or_create_offer_challenge_result do
      arg :offer_slug, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.OfferChallenges.earn/3
    end

    @desc "Create a Bravera referral link."
    field :create_referral, :create_referral_result do
      middleware Middleware.Authenticate
      resolve &Resolvers.Referrals.create_referral/3
    end

    @desc "Register a new user device."
    field :register_device, :register_device_result do
      arg :input, non_null(:register_device_input)
      middleware Middleware.Authenticate
      resolve &Resolvers.Devices.register_device/3
    end

    @desc "Authenticate and receive an authorization token and a user."
    field :login, :user_session_result do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      arg :locale, non_null(:string)
      resolve &Resolvers.Accounts.login/3
    end

    @desc "Sign a user up."
    field :create_user, :user_signup_result do
      arg :input, non_null(:user_signup_input)
      resolve &Resolvers.Accounts.create_user/3
    end

    # Is this a duplicate of earn challenge...? -Sherief
    @desc "Create offer challenge."
    field :create_offer_challenge, :offer_challenge_create_result do
      arg :input, non_null(:offer_challenge_create_input)
      middleware Middleware.Authenticate
      resolve &Resolvers.OfferChallenges.create/3
    end

    @desc "Create segment offer challenge."
    field :join_segment_challenge, :offer_challenge_create_result do
      arg :offer_slug, non_null(:string)
      arg :stripe_token, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.OfferChallenges.create_segment_challenge/3
    end

    @desc "Create activity."
    field :create_activity, :save_activity_result do
      arg :input, non_null(:save_activity_input)
      middleware Middleware.Authenticate
      resolve &Resolvers.Activity.create/3
    end

    @desc "Vote for a partner"
    field :vote_partner, list_of(non_null(:partner_vote)) do
      arg :partner_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Partners.vote_partner/3
    end

    @desc "Register device notification token"
    field :register_notification_token, non_null(:notification_token) do
      middleware Middleware.Authenticate
      arg :token, :string
      resolve &Resolvers.Accounts.register_notification_token/3
    end
  end

  query do
    @desc "Verfiy reset password code"
    field :verify_reset_password_code, :verify_reset_password_code_result do
      arg :reset_token, non_null(:string)
      resolve &Resolvers.Accounts.verify_reset_token/3
    end

    @desc "Get Strava OAUTH url"
    field :get_strava_oauth_url, :string do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.get_strava_oauth_url/3
    end

    @desc "Get User Settings"
    field :get_user_settings, :user do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.get_user_with_settings/3
    end

    @desc "Get Bravera Leaderboard"
    field :get_leaderboard, :leaderboard_result do
      resolve &Resolvers.Accounts.get_leaderboard/3
    end

    @desc "Get latest device sync datetime"
    field :latest_device_sync, :device_latest_sync_result do
      middleware Middleware.Authenticate
      resolve &Resolvers.Devices.get_latest_sync_time/3
    end

    @desc "Refresh existing device token."
    field :refresh_device_token, :register_device_result do
      middleware Middleware.Authenticate
      resolve &Resolvers.Devices.refresh_device_token/3
    end

    @desc "Get a single offer by slug"
    field :get_offer, :offer do
      arg :slug, non_null(:string)
      resolve &Resolvers.Offers.get_offer/3
    end

    @desc "Get a list of all offers"
    field :all_offers, list_of(non_null(:offer)) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Offers.all_offers/3
    end

    @desc "Get offer's offer challenges."
    field :offer_offer_challenges, list_of(:offer_challenge) do
      arg :offer_id, non_null(:integer)
      resolve &Resolvers.Offers.offer_offer_challenges/3
    end

    @desc "Get Challenge Redeem."
    field :get_challenge_redeem, :redeem do
      arg :challenge_id, non_null(:integer)
      middleware Middleware.Authenticate
      resolve &Resolvers.OfferChallenges.get_challenge_redeem/3
    end

    @desc "Get a list of all locations"
    field :all_locations, list_of(non_null(:location)) do
      resolve &Resolvers.Accounts.all_locations/3
    end

    @desc "Get logged in user profile"
    field :user_profile, :user_profile do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.user_profile/3
    end

    @desc "Get profile picture upload URL"
    field :picture_upload, :upload_token do
      arg :picture, non_null(:file_upload_input)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.profile_picture_upload/3
    end

    @desc "Get refresh token for auth"
    field :refresh_auth_token, :refresh_auth_token do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.refresh_auth_token/3
    end

    @desc "Gets latest live challenges for user"
    field :user_live_challenges, list_of(:offer_challenge) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.latest_live_challenges/3
    end

    @desc "Gets latest points and points history for user"
    field :user_points_history, non_null(:user_points_with_history) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Points.latest_points_with_history/3
    end

    @desc "Gets latest future redeems for user"
    field :future_redeems, non_null(list_of(non_null(:redeem))) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.latest_future_redeems/3
    end

    @desc "Gets latest past redeems for user"
    field :past_redeems, non_null(list_of(non_null(:redeem))) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.latest_past_redeems/3
    end

    @desc "Gets latest expired redeems for user"
    field :expired_redeems, non_null(list_of(non_null(:redeem))) do
      middleware Middleware.Authenticate
      resolve &Resolvers.OfferRedeems.latest_expired_redeems/3
    end

    @desc "Gets latest expired challenges for user"
    field :expired_challenges, non_null(list_of(non_null(:offer_challenge))) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.latest_expired_challenges/3
    end

    @desc "Gets all partner locations"
    field :partner_locations, non_null(list_of(non_null(:partner_location))) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Partners.latest_partner_locations/3
    end

    @desc "Gets a partner by their ID"
    field :get_partner, non_null(:partner) do
      arg :partner_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Partners.get_partner/3
    end

    @desc "Gets a breakdown of points from a day"
    field :user_point_day_breakdown, non_null(list_of(non_null(:point))) do
      middleware Middleware.Authenticate
      arg :day, :day
      resolve &Resolvers.Points.point_breakdown_by_day/3
    end
  end

  subscription do
    field :live_challenges, list_of(:offer_challenge) do
      config fn
        _args, %{context: %{current_user: %{id: user_id}}} ->
          {:ok, topic: "#{user_id}"}

        _args, _context ->
          {:error, "unauthorized"}
      end

      #      trigger :earn_offer_challenge, topic: fn
      #        %{user_id: user_id}, _ -> [user_id]
      #        _, _ -> []
      #      end
      #      resolve fn [%{user_id: user_id}], _, _ ->
      #        {:ok, OmegaBravera.Accounts.user_live_challenges(user_id)}
      #      end
    end

    field :live_points, non_null(:user_points_with_history) do
      config fn
        _args, %{context: %{current_user: %{id: user_id}}} ->
          {:ok, topic: "#{user_id}"}

        _args, _context ->
          {:error, "unauthorized"}
      end
    end
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(OmegaBravera.Offers, OmegaBravera.Offers.datasource())
      |> Dataloader.add_source(OmegaBravera.Partners, OmegaBravera.Partners.datasource())

    Map.put(ctx, :loader, loader)
  end

  def plugins, do: [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
end
