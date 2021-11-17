defmodule OmegaBravera.Logger.Oban do
  require Logger

  def handle_event([:oban, :failure], measure, meta, _) do
    {blamed, stack} = Exception.blame(meta.kind, meta.error, meta.stack)
    formatted = Exception.format(meta.kind, blamed, stack)
    duration = System.convert_time_unit(measure.duration, :native, :millisecond)
    Logger.error("[Oban] #{meta.worker} failure in #{duration}ms with: \n\n #{formatted}")
  end

  def handle_event([:oban, :started], measure, meta, _) do
    Logger.warn("[Oban] :started #{meta.worker} at #{measure.start_time}")
  end

  def handle_event([:oban, event], measure, meta, _) do
    duration = System.convert_time_unit(measure.duration, :native, :millisecond)
    Logger.warn("[Oban] #{event} #{meta.worker} ran in #{duration}ms")
  end
end
