defmodule OmegaBraveraWeb.Api.Types.Helper do
  use Absinthe.Schema.Notation

  scalar :date do
    parse fn input ->
      case DateTime.from_iso8601(input.value) do
        {:ok, date, _} -> {:ok, date}

        _ -> :error
      end
    end

    serialize fn date ->
      DateTime.to_iso8601(date)
    end
  end

  scalar :decimal do
    parse fn %{value: value}, _ ->
      Decimal.parse(value)

    _, _ ->
      :error
    end

    serialize &to_string/1
  end
end
