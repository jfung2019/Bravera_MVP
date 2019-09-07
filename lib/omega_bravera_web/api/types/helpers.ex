defmodule OmegaBraveraWeb.Api.Types.Helpers do
  use Absinthe.Schema.Notation

  scalar :date do
    parse(fn input ->
      case DateTime.from_iso8601(input.value) do
        {:ok, date, _} -> {:ok, date}
        _ -> :error
      end
    end)

    serialize(fn date ->
      DateTime.to_iso8601(date)
    end)
  end

  scalar :decimal do
    parse(fn
      %{value: value}, _ ->
        Decimal.parse(value)

      _, _ ->
        :error
    end)

    serialize(&Decimal.to_float/1)
  end

  @desc "An error encountered trying to persist input"
  object :input_error do
    field(:key, non_null(:string))
    field(:message, non_null(:string))
  end
end
