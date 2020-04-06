defmodule OmegaBraveraWeb.Api.Types.Partners do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1, dataloader: 3]
  alias OmegaBravera.{Partners, Offers}

  @desc "Partner type according to if they have offers"
  enum :partner_type do
    value :bravera_partner, as: "bravera_partner", description: "Bravera official partner"

    value :suggested_partner,
      as: "suggested_partner",
      description: "Suggested partner for Bravera"
  end

  object :partner do
    field :id, non_null(:id)
    field :images, non_null(list_of(:string))
    field :introduction, non_null(:string)
    field :name, non_null(:string)
    field :opening_times, non_null(:string)
    field :type, non_null(:partner_type)
    field :location, :partner_location, resolve: dataloader(Partners)

    field :offers, list_of(non_null(:offer)),
      resolve: dataloader(Offers, :offers, args: %{scope: :public_available})

    field :votes, list_of(non_null(:partner_vote)), resolve: dataloader(Partners)
  end

  object :partner_location do
    field :address, non_null(:string)
    field :latitude, non_null(:decimal)
    field :longitude, non_null(:decimal)

    field :partner, non_null(:partner),
      resolve: dataloader(Partners, :partner, args: %{scope: :partner_type})
  end

  object :partner_vote do
    field :user, non_null(:voter), resolve: dataloader(Partners)
    field :partner, non_null(:partner), resolve: dataloader(Partners)
  end

  object :voter do
    field :id, :id
    field :profile_picture, :string
  end
end
