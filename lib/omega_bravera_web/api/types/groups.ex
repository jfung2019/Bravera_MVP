defmodule OmegaBraveraWeb.Api.Types.Groups do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1, dataloader: 3]
  alias OmegaBravera.{Groups, Offers}

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

    field :opening_times, non_null(:string),
      resolve: fn _parent, %{source: %{short_description: description}} ->
        {:ok, description}
      end

    field :short_description, non_null(:string)
    field :type, non_null(:partner_type)
    field :email, :string
    field :website, :string
    field :phone, :string
    field :is_member, non_null(:boolean)

    field :is_private, non_null(:boolean),
      resolve: fn _parent, %{source: %{join_password: pass}} ->
        {:ok, pass != nil}
      end

    field :location, :partner_location, resolve: dataloader(Groups)

    field :offers, list_of(non_null(:offer)),
      resolve: dataloader(Offers, :offers, args: %{scope: :public_available})

    field :votes, list_of(non_null(:partner_vote)), resolve: dataloader(Groups)
  end

  object :partner_location do
    field :address, non_null(:string)
    field :latitude, non_null(:decimal)
    field :longitude, non_null(:decimal)

    field :partner, non_null(:partner),
      resolve: dataloader(Groups, :partner, args: %{scope: :partner_type})
  end

  object :partner_vote do
    field :user, non_null(:voter), resolve: dataloader(Groups)
    field :partner, non_null(:partner), resolve: dataloader(Groups)
  end

  object :voter do
    field :id, :id
    field :profile_picture, :string
  end

  input_object :coordination_map do
    field :latitude, non_null(:float)
    field :longitude, non_null(:float)
  end
end
