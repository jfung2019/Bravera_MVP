defmodule OmegaBraveraWeb.Api.Types.Account do
  use Absinthe.Schema.Notation

  object :user do
    field(:id, :id)
    field(:email, :string)
    field(:firstname, :string)
    field(:lastname, :string)
  end

  object :user_profile do
    field(:total_points, :decimal)
    field(:total_rewards, :integer)
    field(:total_kilometers, :decimal)
    field(:total_challenges, :integer)
    field(:offer_challenges_map, :offer_challenges_map)
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
    field(:credential, :credential)
  end

  # For success reporting
  object :user_signup_result do
    field(:token, :string)
    field(:user, :user)
    field(:user_profile, :user_profile)
  end

  # For success reporting
  object :user_session_result do
    field(:user_session, :user_session)
  end

  object :location do
    field(:id, non_null(:integer))
    field(:name_en, :string)
    field(:name_zh, :string)
  end
end
