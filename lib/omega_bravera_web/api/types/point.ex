defmodule OmegaBraveraWeb.Api.Types.Point do
  use Absinthe.Schema.Notation

  object :point do
    field(:value, :decimal)
    field(:source, :string)
    field(:inserted_at, :date)
    field(:updated_at, :date)
  end
end
