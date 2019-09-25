defmodule OmegaBraveraWeb.Api.Types.Redeem do
  use Absinthe.Schema.Notation

  object :redeem do
    field(:token, :string)
    field(:status, :string)
    field(:reward, :reward)
    field(:inserted_at, :date)
    field(:updated_at, :date)
  end
end
