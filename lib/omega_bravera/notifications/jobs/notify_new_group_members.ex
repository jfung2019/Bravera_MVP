defmodule OmegaBravera.Notifications.Jobs.NotifyNewGroupMembers do
  @moduledoc """
  Checks for any new members joined a group that the user is in and
  sends a push notification to them.
  """
  use Oban.Worker, queue: :notification, max_attempts: 1
  alias OmegaBravera.{Notifications, Notifications.Jobs.Helper}

  @impl Oban.Worker
  def perform(_args, _job) do
    message = "New members joined a group you are in. Go check it out!"

    Notifications.list_notification_devices_with_new_group_member()
    |> Enum.each(&Helper.send_notification(&1, message))
  end
end
