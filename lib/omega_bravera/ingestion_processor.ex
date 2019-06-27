defmodule OmegaBravera.IngestionProcessor do
  use GenServer

  alias OmegaBravera.{
    TaskSupervisor,
    Trackers.StravaApiHelpers,
    Activity.Processor
  }

  require Logger

  @max_retries 5

  def start_link(params), do: GenServer.start_link(__MODULE__, params)

  @impl true
  def init(params) do
    send(self(), :restart_retrieve_activity)

    {:ok,
     %{
       params: params,
       activity_retrieve: %{ref: nil, timer: 0, retry: 0}
     }}
  end

  # The task completed successfully
  @impl true
  def handle_info(
        {ref, {:ok, %Strava.Activity{} = strava_activity}},
        %{activity_retrieve: %{ref: ref}} = state
      ) do
    # We don't care about the DOWN message now, so let's demonitor and flush it
    Process.demonitor(ref, [:flush])
    send(self(), :check_tasks)
    # Attempt to save strava activity.
    Processor.process_activity(strava_activity, state.params)
    Logger.info("IngestionProcessor: activity checking has completed")
    {:noreply, %{state | activity_retrieve: nil}}
  end

  @impl true
  def handle_info(
        {ref, {:error}},
        %{activity_retrieve: %{ref: ref, timer: timer, retry: retry}} = state
      ) do
    timer = timer + 10_000
    retry = retry + 1

    if retry < @max_retries do
      Process.send_after(self(), :restart_retrieve_activity, timer)
      Process.demonitor(ref, [:flush])

      Logger.warn(
        "IngestionProcessor: activity checking has failed, retrying after: #{timer} ms. Retry #{
          retry
        } out of #{@max_retries}"
      )

      {:noreply, %{state | activity_retrieve: %{ref: nil, timer: timer, retry: retry}}}
    else
      {:stop, :unexpected_error, state}
    end
  end

  def handle_info(
        :restart_retrieve_activity,
        %{params: params, activity_retrieve: %{timer: timer, retry: retry}} = state
      ),
      do:
        {:noreply,
         %{
           state
           | activity_retrieve: %{ref: retrieve_activity(params), timer: timer, retry: retry}
         }}

  def handle_info(:check_tasks, %{activity_retrieve: nil} = state), do: {:stop, :normal, state}
  def handle_info(:check_tasks, state), do: {:noreply, state}

  @impl true
  def terminate(:normal, state) do
    Logger.info("IngestionProcessor: Processing has finished.... going down")
    {:shutdown, state}
  end

  def terminate(reason, state) do
    Logger.error("IngestionProcessor: Processer is going down: #{inspect(reason)}")
    {:shutdown, state}
  end

  defp retrieve_activity(params) do
    %{ref: ref} =
      Task.Supervisor.async_nolink(TaskSupervisor, StravaApiHelpers, :process_strava_webhook, [
        params
      ])

    ref
  end
end
