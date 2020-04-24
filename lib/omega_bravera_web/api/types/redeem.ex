defmodule OmegaBraveraWeb.Api.Types.Redeem do
  use Absinthe.Schema.Notation
  alias OmegaBravera.Offers
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :redeem do
    field :token, non_null(:string)
    field :status, non_null(:string)
    field :offer_reward, :offer_reward
    field :offer, :offer, resolve: dataloader(Offers)
    field :offer_challenge, :offer_challenge, resolve: dataloader(Offers)
    field :inserted_at, non_null(:date)
    field :updated_at, non_null(:date)
    field :expired_at, :date
  end
end
