defmodule OmegaBraveraWeb.Api.Types.Redeem do
  use Absinthe.Schema.Notation
  alias OmegaBravera.Offers
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :redeem do
    field :token, :string
    field :status, :string
    field :offer_reward, :offer_reward
    field :offer, :offer, resolve: dataloader(Offers)
    field :offer_challenge, :offer_challenge, resolve: dataloader(Offers)
    field :inserted_at, :date
    field :updated_at, :date
  end
end
