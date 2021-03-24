defmodule OmegaBravera.Notifications.Jobs.NotifyNewFriend do
  @moduledoc """
  Send notification when there is a new friend request or someone accepted a friend request
  """
  use Oban.Worker, queue: :default, max_attempts: 1
  alias OmegaBravera.{Notifications, Notifications.Jobs.Helper}

  @impl Oban.Worker
  def perform(%{"receiver_id" => receiver_id, "status" => "pending"}, _job) do
    message = "Someone has sent you a friend request. Open Bravera app and find out who."

    Notifications.list_notification_devices_by_user_id(receiver_id)
    |> Enum.each(&Helper.send_notification(&1, message))

    :ok
  end

  @impl Oban.Worker
  def perform(%{"requester_id" => requester_id, "status" => "accepted"}, _job) do
    message = "Someone accepted your friend request. Open Bravera app and find out who."

    Notifications.list_notification_devices_by_user_id(requester_id)
    |> Enum.each(&Helper.send_notification(&1, message))

    :ok
  end
end
