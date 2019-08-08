defmodule OmegaBraveraWeb.Schema.Types.Offer do
  use Absinthe.Schema.Notation

  object :offer do
    field(:id, non_null(:integer))
    field(:name, non_null(:string))
  end
end
