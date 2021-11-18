defmodule OmegaBravera.Logger.Ecto do
  require Logger

  def handle_event(
        [:omega_bravera, :repo, :query],
        %{query_time: time},
        %{query: query, params: params},
        _config
      ) do
    time = System.convert_time_unit(time, :native, :millisecond)

    if time > 300 do
      Logger.warn("Query time: #{time}ms with query: #{query} with params: #{inspect(params)}")
    end
  end

  def handle_event(_event, _measurements, _metadata, _config), do: :ok
end
