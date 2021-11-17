defmodule OmegaBravera.Logger.Absinthe do
  require Logger

  def handle_event(
        [:absinthe, :resolve, :field, :stop],
        %{duration: duration},
        %{middleware: middleware},
        _config
      ) do
    time = System.convert_time_unit(duration, :native, :millisecond)

    if time > 300 do
      Logger.warn("Query time: #{time}ms with middleware and query: #{inspect(middleware)}")
    end
  end
end
