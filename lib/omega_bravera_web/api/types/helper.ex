defmodule OmegaBraveraWeb.Schema.Types.Helper do
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
end
