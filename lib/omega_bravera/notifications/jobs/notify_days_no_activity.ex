defmodule OmegaBravera.Notifications.Jobs.NotifyDaysNoActivity do
  @moduledoc """
  Checks for latest activity of each user who has allowed us
  to send push notifications to, and sends a push that they need
  to sync up their data.
  """
  use Oban.Worker, queue: :default, max_attempts: 1
  alias OmegaBravera.Notifications
  alias Pigeon.FCM.Notification

  @impl Oban.Worker
  def perform(_args, _job) do
    4
    |> Notifications.list_notification_devices_with_last_activity_from()
    |> Enum.each(fn token ->
      token
      |> Notification.new(%{
        "body" =>
          "You could be converting walking into points! Don't miss out! Open Bravera and check your progress now.",
        "title" => "Bravera",
        "sound" => "default",
        "badge" => "1"
      })
      |> Notification.put_priority(:high)
      |> Pigeon.FCM.push()
    end)
  end
end
