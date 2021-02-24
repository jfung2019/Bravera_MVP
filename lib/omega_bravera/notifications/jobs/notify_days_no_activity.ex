defmodule OmegaBravera.Notifications.Jobs.NotifyDaysNoActivity do
  @moduledoc """
  Checks for latest activity of each user who has allowed us
  to send push notifications to, and sends a push that they need
  to sync up their data.
  """
  use Oban.Worker, queue: :notification, max_attempts: 1
  alias OmegaBravera.{Notifications, Notifications.Jobs.Helper}

  @impl Oban.Worker
  def perform(_args, _job) do
    message =
      "You could be converting walking into points! Don't miss out! Open Bravera and check your progress now."

    Notifications.list_notification_devices_with_last_activity_every_7_days()
    |> Enum.each(&Helper.send_notification(&1, message))
  end
end
