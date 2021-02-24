defmodule OmegaBravera.Notifications.Jobs.NotifyNewMessage do
  @moduledoc """
  Check for new messages in chat and send a push notification to them
  """
  use Oban.Worker, queue: :notification, max_attempts: 1
  alias OmegaBravera.{Notifications, Notifications.Jobs.Helper}

  @impl Oban.Worker
  def perform(_args, _job) do
    message = "There are missed messages inside your chat group(s)."

    Notifications.list_notification_devices_with_new_message()
    |> Enum.each(&Helper.send_notification(&1, message))
  end
end
