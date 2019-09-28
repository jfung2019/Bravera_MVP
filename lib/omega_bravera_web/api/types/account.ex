defmodule OmegaBraveraWeb.Api.Types.Account do
  use Absinthe.Schema.Notation

  object :user do
    field(:id, non_null(:id))
    field(:email, :string)
    field(:firstname, :string)
    field(:lastname, :string)
    field(:profile_picture, :string)
    field(:strava, :strava)
  end

  object :strava do
    field(:strava_profile_picture, :string)
  end

  object :user_profile do
    field(:total_points, non_null(:decimal))
    field(:total_rewards, non_null(:integer))
    field(:total_kilometers, non_null(:decimal))
    field(:total_challenges, non_null(:integer))
    field(:offer_challenges_map, :offer_challenges_map)
    field(:profile_picture, :string)
    field(:strava, :strava)
    field(:future_redeems, list_of(:redeem))
    field(:past_redeems, list_of(:redeem))
    field(:points_history, list_of(:point))
  end

  object :user_session do
    field(:token, :string)
    field(:user, :user)
    field(:user_profile, :user_profile)
  end

  input_object :credential do
    field(:password, non_null(:string))
    field(:password_confirm, non_null(:string))
  end

  input_object :user_signup_input do
    field(:firstname, non_null(:string))
    field(:lastname, non_null(:string))
    field(:accept_terms, non_null(:boolean))
    field(:location_id, non_null(:integer))
    field(:locale, non_null(:string))
    # should create an email scalar type to validate.
    field(:email, non_null(:string))
    field(:referral_token, :string)
    field(:credential, :credential)
  end

  # For success reporting
  object :user_signup_result do
    field(:token, non_null(:string))
    field(:user, non_null(:user))
    field(:user_profile, non_null(:user_profile))
  end

  # For success reporting
  object :user_session_result do
    field(:user_session, :user_session)
  end

  object :location do
    field(:id, non_null(:integer))
    field(:name_en, non_null(:string))
    field(:name_zh, non_null(:string))
  end
end
