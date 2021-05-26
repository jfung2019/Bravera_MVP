defmodule OmegaBraveraWeb.Api.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
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
  import_types Types.Groups

  mutation do
    @desc "Set profile picture"
    field :set_profile_picture, :user do
      arg :picture_url, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.profile_picture_update/3
    end

    @desc "Set username"
    field :set_username, :user do
      arg :username, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.username_update/3
    end

    @desc "Update email permission"
    field :update_email_permission, list_of(non_null(:email_category)) do
      arg :email_permissions, list_of(non_null(:string))
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.update_user_email_permission/3
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

    @desc "Connect to strava"
    field :connect_to_strava, non_null(:strava_user) do
      arg :code, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.connect_to_strava/3
    end

    @desc "Switch sync type"
    field :switch_user_sync_type, :sync_method do
      middleware Middleware.Authenticate
      arg :sync_type, non_null(:sync_type)
      resolve &Resolvers.Accounts.switch_user_sync_type/3
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
      arg :stripe_token, :string
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

    @desc "Verify user's email"
    field :verify_email, non_null(:user) do
      arg :code, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.verify_email/3
    end

    @desc "Change user's email"
    field :change_email, non_null(:user) do
      arg :email, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.change_email/3
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
      resolve &Resolvers.Groups.vote_partner/3
    end

    @desc "Register device notification token"
    field :register_notification_token, :notification_token do
      middleware Middleware.Authenticate
      arg :token, non_null(:string)
      resolve &Resolvers.Accounts.register_notification_token/3
    end

    @desc "Enables/Disables push notifications from server to all registered devices"
    field :enable_push_notifications, :user do
      middleware Middleware.Authenticate
      arg :enable, non_null(:boolean)
      resolve &Resolvers.Accounts.enable_push_notifications/3
    end

    @desc "Resends welcome email to verify account"
    field :resend_welcome_email, :user do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.resend_welcome_email/3
    end

    @desc "Joins a partner"
    field :join_partner, :partner do
      middleware Middleware.Authenticate
      arg :partner_id, non_null(:id)
      arg :password, :string, default_value: nil
      resolve &Resolvers.Groups.join_partner/3
    end

    @desc "Leave a group"
    field :leave_group, :partner do
      arg :group_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Groups.leave_group/3
    end

    @desc "create a friend request"
    field :create_friend_request, :friend_request do
      arg :receiver_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.create_friend_request/3
    end

    @desc "accept a friend request"
    field :accept_friend_request, :friend_request do
      arg :requester_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.accept_friend_request/3
    end

    @desc "reject a friend request"
    field :reject_friend_request, :friend_request do
      arg :requester_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.reject_friend_request/3
    end

    @desc "unfriend user"
    field :unfriend_user, :unfriend_result do
      arg :user_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.unfriend_user/3
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

    @desc "List email categories"
    field :list_email_categories, list_of(non_null(:email_category)) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.list_email_categories/3
    end

    @desc "Get User Settings"
    field :get_user_settings, :user do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.get_user_with_settings/3
    end

    @desc "Get the syncing method of user"
    field :get_user_syncing_method, non_null(:sync_method) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.get_user_syncing_method/3
    end

    @desc "Get Bravera Leaderboard"
    field :get_leaderboard, :leaderboard_result do
      resolve &Resolvers.Accounts.get_leaderboard/3
    end

    @desc "Get Bravera Leaderboard"
    field :get_partner_leaderboard, :leaderboard_result do
      arg :partner_id, non_null(:id)
      resolve &Resolvers.Accounts.get_partner_leaderboard/3
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

    @desc "Search Offers with pagination"
    connection field :search_offers_paginated, node_type: :offer do
      arg :keyword, :string
      arg :location_id, :integer
      arg :coordinate, :coordination_map
      middleware Middleware.Authenticate
      resolve &Resolvers.Offers.search_offers_paginated/3
    end

    @desc "Get offer's offer challenges."
    field :offer_offer_challenges, list_of(:offer_challenge_locked) do
      arg :offer_id, non_null(:id)
      resolve &Resolvers.Offers.offer_offer_challenges/3
    end

    @desc "Get offer's offer challenges, but paginated."
    connection field :offer_offer_challenges_paginated, node_type: :offer_challenge_locked do
      arg :offer_id, non_null(:id)
      resolve &Resolvers.Offers.offer_offer_challenges_paginated/3
    end

    @desc "Get Challenge Redeem."
    field :get_challenge_redeem, :redeem do
      arg :challenge_id, non_null(:id)
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

    @desc "Get logged in user profile with total kms and points from last sync time"
    field :user_profile_with_last_sync_data, :last_sync_data_user_profile do
      arg :last_sync, non_null(:string)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.user_profile_with_last_sync_data/3
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
      resolve &Resolvers.Groups.latest_partner_locations/3
    end

    @desc "Get all partner locations based on coordinate"
    field :list_partner_locations, non_null(:partner_locations_result) do
      arg :coordinate, :coordination_map
      middleware Middleware.Authenticate
      resolve &Resolvers.Groups.list_partner_locations/3
    end

    @desc "Get all offer coordinates based on coordinate"
    field :list_offer_coordinates, non_null(:offer_coordinates_result) do
      arg :coordinate, :coordination_map
      middleware Middleware.Authenticate
      resolve &Resolvers.Offers.list_offer_coordinates/3
    end

    @desc "Gets a partner by their ID"
    field :get_partner, non_null(:partner) do
      arg :partner_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Groups.get_partner/3
    end

    @desc "Gets all partners"
    field :get_partners, non_null(list_of(:partner)) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Groups.get_partners/3
    end

    connection field :get_partners_paginated, node_type: :partner do
      middleware Middleware.Authenticate
      resolve &Resolvers.Groups.get_partners_paginated/3
    end

    connection field :search_groups_paginated, node_type: :partner do
      arg :keyword, :string
      arg :global, non_null(:boolean)
      middleware Middleware.Authenticate
      resolve &Resolvers.Groups.search_groups_paginated/3
    end

    @desc "Gets all joined partners"
    field :list_joined_partners, non_null(list_of(:partner)) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Groups.list_joined_partners/3
    end

    @desc "Gets a breakdown of points from a day"
    field :user_point_day_breakdown, non_null(list_of(non_null(:point))) do
      middleware Middleware.Authenticate
      arg :day, :day
      resolve &Resolvers.Points.point_breakdown_by_day/3
    end

    @desc "in app notification checking for new offers, new groups and expiring redeems"
    field :home_in_app_noti, non_null(:home_in_app_noti) do
      arg :coordinate, :coordination_map
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.noti_offer_group_redeem/3
    end

    @desc "list and search friends paginated"
    connection field :list_friends, node_type: :user_profile do
      arg :keyword, :string
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.list_friends/3
    end

    @desc "list friend requests"
    field :list_friend_requests, list_of(non_null(:friend_request)) do
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.list_friend_requests/3
    end

    @desc "list users that can send friend request to"
    connection field :list_possible_friends, node_type: :user_profile_locked do
      arg :keyword, :string
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.list_possible_friends/3
    end

    @desc "Compare with friend"
    field :compare_with_friend, non_null(:friend_compare) do
      arg :friend_user_id, non_null(:id)
      middleware Middleware.Authenticate
      resolve &Resolvers.Accounts.compare_with_friend/3
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
      |> Dataloader.add_source(OmegaBravera.Groups, OmegaBravera.Groups.datasource(ctx))
      |> Dataloader.add_source(OmegaBravera.Accounts, OmegaBravera.Accounts.datasource())

    Map.put(ctx, :loader, loader)
  end

  def plugins, do: [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
end
