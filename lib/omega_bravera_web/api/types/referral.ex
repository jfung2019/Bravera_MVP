defmodule OmegaBraveraWeb.Api.Types.Referral do
  use Absinthe.Schema.Notation

  object :referral do
    field(:id, non_null(:integer))
    field(:token, non_null(:string))
    field(:user_id, non_null(:id))
    field(:referred_user_id, :id)
    field(:status, non_null(:string))
    field(:bonus_points, non_null(:string))
    field(:inserted_at, non_null(:date))
    field(:updated_at, non_null(:date))
  end

  object :create_referral_result do
    # TODO: should return a URL instead be used in an endpoint?
    field(:referral, :referral)
  end
end
