defmodule OmegaBravera.IngestionProcessor do
  use GenServer

  alias OmegaBravera.{
    TaskSupervisor,
    Trackers.StravaApiHelpers,
    Activity.Processor
  }

  require Logger

  def start_link(params), do: GenServer.start_link(__MODULE__, params)

  @impl true
  def init(params) do
    send(self(), :restart_retrieve_activity)

    {:ok,
     %{
       params: params,
       activity_retrieve: %{ref: nil, timer: 0}
     }}
  end

  # The task completed successfully
  @impl true
  def handle_info(
        {ref, {:ok, %Strava.DetailedActivity{} = strava_activity}},
        %{activity_retrieve: %{ref: ref}} = state
      ) do
    # No need to continue to monitor
    Process.demonitor(ref, [:flush])
    # Attempt to save strava activity.
    Processor.process_activity(strava_activity, state.params)
    Logger.info("IngestionProcessor: activity checking has completed")
    {:noreply, %{state | activity_retrieve: nil}}
  end

  def handle_info({ref, {:error, :no_user_matching_athlete_id}}, state) do
    Process.demonitor(ref, [:flush])
    Logger.info("Strava sent an activity of a non-existing user. Ignoring...")
    {:stop, :normal, state}
  end

  def handle_info({ref, {:error, %Tesla.Env{status: 404}}}, state) do
    Process.demonitor(ref, [:flush])
    Logger.info("Strava sent an activity of a non-existing activity. Ignoring...")
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(
        {ref, {:error, _}},
        %{activity_retrieve: %{ref: ref, timer: timer}} = state
      ) do
    timer = timer + 10_000

    Process.send_after(self(), :restart_retrieve_activity, timer)
    Process.demonitor(ref, [:flush])

    Logger.warn("IngestionProcessor: activity checking has failed, retrying after: #{timer} ms.")

    {:noreply, %{state | activity_retrieve: %{ref: nil, timer: timer}}}
  end

  def handle_info(
        :restart_retrieve_activity,
        %{params: params, activity_retrieve: %{timer: timer}} = state
      ),
      do:
        {:noreply,
         %{
           state
           | activity_retrieve: %{ref: retrieve_activity(params), timer: timer}
         }}

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
