defmodule OmegaBraveraWeb.Api.Types.Reward do
  use Absinthe.Schema.Notation

  object :offer_reward do
    field(:name, non_null(:string))
    field(:value, :integer)
    field(:offer, :offer)
  end
end
