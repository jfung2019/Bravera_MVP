defmodule OmegaBraveraWeb.Api.Types.Redeem do
  use Absinthe.Schema.Notation

  object :redeem do
    field(:token, :string)
    field(:status, :string)
    field(:offer_reward, :offer_reward)
    field(:offer, :offer)
    field(:offer_challenge, :offer_challenge)
    field(:inserted_at, :date)
    field(:updated_at, :date)
  end
end
