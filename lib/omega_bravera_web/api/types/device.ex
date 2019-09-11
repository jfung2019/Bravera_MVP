defmodule OmegaBraveraWeb.Api.Types.Device do
  use Absinthe.Schema.Notation

  object :device do
    field(:id, :id)
    field(:active, :boolean)
    field(:uuid, :string)
    field(:user, :user)
  end

  object :register_device_result do
    field(:token, non_null(:string))
    field(:expires_at, non_null(:date)) # Actually datetime.
  end

  input_object :register_device_input do
    field(:uuid, non_null(:string))
    field(:active, non_null(:boolean))
  end
end
