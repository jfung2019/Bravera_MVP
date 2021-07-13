defmodule OmegaBraveraWeb.Api.Types.Point do
  use Absinthe.Schema.Notation

  object :point_summary do
    field :pos_value, :decimal
    field :neg_value, :decimal
    # TODO: remove from app code and here in the future
    field :distance, :decimal
    field :source, :string
    field :inserted_at, :date
    field :updated_at, :date
  end

  object :point do
    field :value, :decimal
    field :source, :string
    field :inserted_at, :date
  end
end
