defmodule OmegaBraveraWeb.Api.Types.Helpers do
  use Absinthe.Schema.Notation

  scalar :date do
    parse(fn input ->
      case Timex.parse(input.value, "{ISO:Extended}") do
        {:ok, iso_date} ->
          {:ok, date} = DateTime.from_naive(iso_date, "Etc/UTC")
          {:ok, date}

        _ ->
          :error
      end
    end)

    serialize(fn date ->
        try do
          DateTime.to_iso8601(date)
        catch
          _ ->
            Date.to_iso8601(date)
        end
      end)
  end

  scalar :day do
    description "Day in ISO 8601 format"
    parse fn %{value: value} -> Date.from_iso8601(value) end
    serialize &Date.to_iso8601/1
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
