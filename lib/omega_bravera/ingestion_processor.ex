defmodule OmegaBravera.IngestionProcessor do
  use GenServer
  alias OmegaBravera.{TaskSupervisor, Challenges.ActivitiesIngestion, Offers.OfferActivitiesIngestion}
  require Logger

  def start_link(params), do: GenServer.start_link(__MODULE__, params)

  @impl true
  def init(params) do
    send(self(), :restart_offers)
    send(self(), :restart_ngos)
    {:ok,
     %{
       params: params,
       offers: %{ref: nil, timer: 0},
       ngos: %{ref: nil, timer: 0}
     }}
  end

  # The task completed successfully
  @impl true
  def handle_info({ref, _answer}, %{offers: %{ref: ref}} = state) do
    # We don't care about the DOWN message now, so let's demonitor and flush it
    Process.demonitor(ref, [:flush])
    send(self(), :check_tasks)
    Logger.info("offer checking has completed")
    {:noreply, %{state | offers: nil}}
  end

  # The task failed
  def handle_info(
        {:DOWN, ref, :process, _pid, _reason},
        %{offers: %{ref: ref, timer: timer}} = state
      ) do
    timer = timer + 10_000
    Process.send_after(self(), timer, :restart_offers)
    Process.demonitor(ref, [:flush])
    Logger.warn("offer checking has failed, retrying after: #{timer} ms")
    {:noreply, %{state | offers: %{ref: nil, timer: timer}}}
  end

  # The task completed successfully
  def handle_info({ref, _answer}, %{ngos: %{ref: ref}} = state) do
    # We don't care about the DOWN message now, so let's demonitor and flush it
    Process.demonitor(ref, [:flush])
    send(self(), :check_tasks)
    Logger.info("ngo checking has completed")
    {:noreply, %{state | ngos: nil}}
  end

  # The task failed
  def handle_info(
        {:DOWN, ref, :process, _pid, _reason},
        %{ngos: %{ref: ref, timer: timer}} = state
      ) do
    timer = timer + 10_000
    Process.send_after(self(), timer, :restart_ngos)
    Process.demonitor(ref, [:flush])
    Logger.warn("NGO checking has failed, retrying after #{timer}")
    {:noreply, %{state | ngos: %{ref: nil, timer: timer}}}
  end

  def handle_info(:restart_offers, %{params: params, offers: %{timer: timer}} = state),
    do: {:noreply, %{state | offers: %{ref: process_offers(params), timer: timer}}}

  def handle_info(:restart_ngos, %{params: params, offers: %{timer: timer}} = state),
    do: {:noreply, %{state | ngos: %{ref: process_ngos(params), timer: timer}}}

  def handle_info(:check_tasks, %{offers: nil, ngos: nil} = state), do: {:stop, :normal, state}
  def handle_info(:check_tasks, state), do: {:noreply, state}

  @impl true
  def terminate(:normal, state) do
    Logger.info("Processing has finished.... going down")
    {:shutdown, state}
  end

  def terminate(reason, state) do
    Logger.error("Ingestion Processer is going down: #{reason}")
    {:shutdown, state}
  end

  defp process_offers(params) do
    %{ref: ref} =
      Task.Supervisor.async_nolink(TaskSupervisor, OfferActivitiesIngestion, :start, [params])

    ref
  end

  defp process_ngos(params) do
    %{ref: ref} =
      Task.Supervisor.async_nolink(TaskSupervisor, ActivitiesIngestion, :process_strava_webhook, [
        params
      ])

    ref
  end
end
