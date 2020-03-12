defmodule OmegaBraveraWeb.Api.Types.Partners do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias OmegaBravera.{Partners, Offers}

  object :partner do
    field :images, non_null(list_of(:string))
    field :introduction, non_null(:string)
    field :name, non_null(:string)
    field :opening_times, non_null(:string)
    field :location, :partner_location, resolve: dataloader(Partners)
    field :offers, list_of(non_null(:offer)), resolve: dataloader(Offers)
  end

  object :partner_location do
    field :address, non_null(:string)
    field :latitude, non_null(:decimal)
    field :longitude, non_null(:decimal)
    field :partner, non_null(:partner), resolve: dataloader(Partners)
  end

  object :partner_vote do
    field :user, non_null(:voter), resolve: dataloader(Partners)
    field :partner, non_null(:partner), resolve: dataloader(Partners)
  end

  object :voter do
    field :profile_picture, :string
  end
end
