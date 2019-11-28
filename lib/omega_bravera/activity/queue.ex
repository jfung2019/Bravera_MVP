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

    # Get the number of activities at specific time to confirm there are no duplicate activities by date.
    number_of_duplicates =
      Activities.get_user_activities_at_time(
        value.activity_params,
        value.user.id,
        value.device_id
      )

    result =
      Activities.create_app_activity(
        value.activity_params,
        value.user.id,
        value.device_id,
        number_of_duplicates
      )

    case result do
      {:ok, activity} ->
        user_with_points = OmegaBravera.Accounts.get_user_with_todays_points(value.user)
        Logger.info(
          "Activity Create Queue: Successfully created user_id: #{value.user.id} #{value.user.firstname}'s activity: #{activity}"
        )

        # Add reward points if activity is eligible.
        case Points.create_points_from_activity(activity, user_with_points) do
          {:ok, _point} ->
            Logger.info(
              "Activity Create Queue: Successfully created points for activity: #{activity.id}"
            )

          {:error, reason} ->
            Logger.warn(
              "Activity Create Queue: Could not create points for activity, reason: #{
                inspect(reason)
              }"
            )
        end

      {:error, changeset} ->
        Logger.warn(
          "Activity Create Queue: Could not create activity, reason: #{
            inspect(changeset)
          }"
        )

        nil
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
