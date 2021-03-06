defmodule OmegaBraveraWeb.Api.Types.Account do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias OmegaBravera.{Accounts, Points}

  object :user do
    field :id, non_null(:id)
    field :email, non_null(:string)
    field :firstname, :string
    field :lastname, :string
    field :username, :string
    field :locale, :string
    field :email_verified, non_null(:boolean)
    field :profile_picture, :string
    field :strava, :strava, resolve: dataloader(OmegaBravera.Accounts)
    field :total_points, :decimal
    field :total_points_this_week, :decimal
    field :total_points_this_month, :decimal
    field :total_kilometers, :decimal
    field :total_kilometers_this_week, :decimal
    field :total_kilometers_this_month, :decimal
    field :location_id, :integer
    field :setting, :setting
    field :push_notifications, non_null(:boolean)
    field :email_permissions, list_of(:string)
  end

  object :user_locked do
    field :username, non_null(:string)
    field :profile_picture, :string
    field :sync_type, non_null(:sync_type)
    field :strava, :strava, resolve: dataloader(OmegaBravera.Accounts)
  end

  object :notification_token do
    field :token, non_null(:string)
  end

  object :setting do
    field :weight, :decimal
    field :date_of_birth, :date
    field :gender, :string
  end

  object :send_reset_password_code_result do
    field :status, :string
  end

  object :verify_reset_password_code_result do
    field :status, :string
  end

  object :delete_profile_picture_result do
    field :status, :string
  end

  object :forgot_password_change_password_result do
    field :status, :string
  end

  input_object :user_settings_input do
    field :username, non_null(:string)
    field :firstname, non_null(:string)
    field :lastname, non_null(:string)
    field :locale, non_null(:string)
    field :location_id, non_null(:integer)
    field :setting, non_null(:setting_input)
  end

  input_object :setting_input do
    field :date_of_birth, non_null(:date)
    field :gender, non_null(:string)
  end

  object :strava do
    field :athlete_id, :id
    field :strava_profile_picture, :string
  end

  object :user_profile do
    field :id, non_null(:id)
    field :email, non_null(:string)
    field :firstname, :string
    field :lastname, :string
    field :username, :string
    field :sync_type, non_null(:sync_type)
    field :email_permissions, list_of(:string)

    field :total_points, non_null(:decimal),
      resolve: fn _parent, %{source: %{id: user_id}} ->
        {:ok, Points.total_points(user_id)}
      end

    field :total_points_today, non_null(:decimal)
    field :total_points_this_week, non_null(:decimal)
    field :total_rewards, non_null(:integer)
    field :total_kilometers, non_null(:decimal)
    field :total_kilometers_today, non_null(:decimal)
    field :total_kilometers_this_week, non_null(:decimal)
    field :total_kilometers_this_month, non_null(:decimal)
    field :daily_points_limit, non_null(:integer)
    field :total_challenges, non_null(:integer)
    field :offer_challenges_map, :offer_challenges_map
    field :profile_picture, :string
    field :strava, :strava, resolve: dataloader(OmegaBravera.Accounts)

    field :future_redeems, list_of(:redeem),
      resolve: fn _parent, %{source: %{id: user_id}} ->
        {:ok, Accounts.future_redeems(user_id)}
      end

    field :past_redeems, list_of(:redeem),
      resolve: fn _parent, %{source: %{id: user_id}} ->
        {:ok, Accounts.past_redeems(user_id)}
      end

    field :points_history, list_of(:point_summary),
      resolve: fn _parent, %{source: %{id: user_id}} ->
        {:ok, Points.user_points_history_summary(user_id)}
      end

    field :email_verified, non_null(:boolean)
    field :inserted_at, non_null(:date)
    field :groups, list_of(non_null(:partner)), resolve: dataloader(OmegaBravera.Groups)
    field :friend_status, non_null(:string)
  end

  connection(node_type: :user_profile)

  object :user_profile_locked do
    field :id, non_null(:id)
    field :username, :string
    field :profile_picture, :string
    field :friend_status, non_null(:string)
  end

  connection(node_type: :user_profile_locked)

  object :friend_profile do
    field :id, non_null(:id)
    field :firstname, :string
    field :lastname, :string
    field :sync_type, non_null(:sync_type)
    field :username, non_null(:string)

    field :total_points, non_null(:decimal),
      resolve: fn _parent, %{source: %{id: user_id}} ->
        {:ok, Points.total_points(user_id)}
      end

    field :total_points_this_week, non_null(:decimal)
    field :total_kilometers, non_null(:decimal)
    field :total_kilometers_today, non_null(:decimal)
    field :total_kilometers_this_week, non_null(:decimal)
    field :total_kilometers_this_month, non_null(:decimal)
    field :profile_picture, :string
    field :strava, :strava, resolve: dataloader(OmegaBravera.Accounts)

    field :inserted_at, non_null(:date)
    field :groups, list_of(non_null(:partner)), resolve: dataloader(OmegaBravera.Groups)
    field :friend_status, non_null(:string)
  end

  connection(node_type: :friend_profile)

  object :user_points_with_history do
    field :balance, non_null(:decimal)
    field :history, non_null(list_of(:point_summary))
  end

  object :user_session do
    field :token, :string
    field :user, :user

    field :user_profile, :user_profile,
      resolve: fn _parent, %{source: %{user: %{id: user_id}}} ->
        # TODO: probably don't inline this for the future
        {:ok, Accounts.api_user_profile(user_id)}
      end
  end

  input_object :credential do
    field :password, non_null(:string)
    field :password_confirm, non_null(:string)
  end

  input_object :user_signup_input do
    field :firstname, non_null(:string)
    field :lastname, non_null(:string)
    field :accept_terms, non_null(:boolean)
    field :location_id, non_null(:integer)
    field :locale, non_null(:string)
    # should create an email scalar type to validate.
    field :email, non_null(:string)
    field :referral_token, :string
    field :credential, :credential
    field :setting, non_null(:setting_input)
  end

  # For success reporting
  object :user_signup_result do
    field :token, non_null(:string)
    field :user, non_null(:user)

    field :user_profile, non_null(:user_profile),
      resolve: fn _parent, %{source: %{user: %{id: user_id}}} ->
        # TODO: probably don't inline this for the future
        {:ok, Accounts.api_user_profile(user_id)}
      end
  end

  # For success reporting
  object :user_session_result do
    field :user_session, :user_session
  end

  object :leaderboard_result do
    field :this_week, list_of(:leaderboard_user)
    field :this_month, list_of(:leaderboard_user)
    field :all_time, list_of(:leaderboard_user)
  end

  object :leaderboard_user do
    field :id, non_null(:id)
    field :username, non_null(:string)
    field :sync_type, non_null(:sync_type)
    field :profile_picture, :string
    field :is_friend, non_null(:boolean)
    field :strava, :strava, resolve: dataloader(OmegaBravera.Accounts)
    field :total_points, :decimal
    field :total_points_this_week, :decimal
    field :total_points_this_month, :decimal
    field :total_kilometers, :decimal
    field :total_kilometers_this_week, :decimal
    field :total_kilometers_this_month, :decimal
  end

  object :location do
    field :id, non_null(:integer)
    field :name_en, non_null(:string)
    field :name_zh, non_null(:string)
  end

  input_object :file_upload_input do
    field :name, :string
    field :mime_type, :string
  end

  object :upload_token do
    field :upload_url, :string
    field :file_url, :string
  end

  object :refresh_auth_token do
    field :token, :string
  end

  object :home_in_app_noti do
    field :new_offer, non_null(:boolean)
    field :new_group, non_null(:boolean)
    field :expiring_reward, non_null(:boolean)
  end

  enum :friend_status do
    value :pending, description: "Friend request pending accept/reject"
    value :stranger, description: "No friend request has been made"

    value :accepted,
      description: "Friend request accepted"
  end

  object :possible_friend do
    field :id, non_null(:id)
    field :username, non_null(:string)
    field :firstname, non_null(:string)
    field :lastname, non_null(:string)
    field :profile_picture, :string
  end

  object :friend_receiver do
    field :id, non_null(:id)
    field :username, non_null(:string)
  end

  object :friend_request do
    field :receiver, non_null(:friend_receiver)
    field :requester, non_null(:possible_friend), resolve: dataloader(Accounts)
    field :status, non_null(:friend_status)
  end

  object :unfriend_result do
    field :unfriended_user_id, non_null(:id)
  end

  object :friend_compare do
    field :user, non_null(:user_profile)
    field :friend, non_null(:friend_profile)
  end

  object :email_category do
    field :title, non_null(:string)
    field :description, non_null(:string)
    field :permitted, non_null(:boolean)
  end

  enum :sync_type do
    value :device, description: "Sync activities with device, i.e. Google Fit / Apple Health"
    value :strava, description: "Sync activities with Strava"

    value :pedometer,
      description: "Sync activities with Bravera Pedometer, only available on Android"
  end

  object :sync_method do
    field :sync_type, non_null(:sync_type)
    field :strava_connected, non_null(:boolean)
  end

  object :strava_user do
    field :athlete_id, non_null(:integer)
    field :user_id, non_null(:id)
  end
end
