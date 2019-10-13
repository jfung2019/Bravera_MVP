defmodule OmegaBraveraWeb.Api.Types.Offer do
  use Absinthe.Schema.Notation

  object :offer do
    field(:id, non_null(:integer))
    field(:name, non_null(:string))
    field(:slug, non_null(:string))
    field(:toc, non_null(:string))
    field(:logo, non_null(:string))
    field(:image, non_null(:string))
    field(:target, non_null(:integer))
    field(:end_date, non_null(:date))
    field(:offer_challenges, list_of(:offer_challenge))
  end
end
