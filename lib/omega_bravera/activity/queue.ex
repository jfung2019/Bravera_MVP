defmodule OmegaBravera.Activity.Queue do
  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Activity.Activities
  alias OmegaBravera.Points
  use GenServer

  require Logger

  ### GenServer API calls
  def init(state), do: {:ok, state}

  def handle_call(:dequeue, _from, [value | state]) do
    Logger.info("Activity Create Queue: creating activity...")

    result =
      Activities.create_app_activity(
        value.activity_params,
        value.user.id,
        value.device_id
      )

    case result do
      {:ok, activity} ->
        Logger.info(
          "Activity Create Queue: Successfully created user_id: #{inspect(value.user.id)} #{inspect(value.user.firstname)}'s activity: #{inspect(activity)}"
        )

        # Add reward points if activity is eligible.
        Points.add_points_to_user_from_activity(activity)

      {:error, changeset} ->
        Logger.warn(
          "Activity Create Queue: Could not create activity, reason: #{inspect(changeset)}"
        )

        {:error, changeset}
    end

    {:reply, result, state}
  end

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  def handle_cast({:enqueue, value}, state) do
    {:noreply, state ++ [value]}
  end

  ### Client API / Helper functions

  # Name arg should be user firstname + id
  def start_link(state \\ [], name) do
    Logger.info("Activity Create Queue: starting for #{name}..")
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def queue(server_name), do: GenServer.call(server_name, :queue)
  def enqueue(server_name, value), do: GenServer.cast(server_name, {:enqueue, value})
  def dequeue(server_name), do: GenServer.call(server_name, :dequeue)

  # Helpers
  def generate_server_name(%User{firstname: firstname, id: id}),
    do: String.to_atom("#{firstname}_#{id}")
end
