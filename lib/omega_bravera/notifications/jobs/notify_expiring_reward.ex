defmodule OmegaBravera.Notifications.Jobs.NotifyExpiringReward do
  @moduledoc """
  Checks for any expiring rewards within the next 3 days and
  sends a push notification to them.
  """
  use Oban.Worker, queue: :default, max_attempts: 1
  alias OmegaBravera.Notifications
  alias Pigeon.FCM.Notification

  @impl Oban.Worker
  def perform(_args, _job) do
    -3
    |> Notifications.list_notification_devices_with_expiring_offer_redeem()
    |> Enum.each(fn token ->
      token
      |> Notification.new(%{
        "body" => "A reward you 'own' expires soon! The clock is ticking ... claim it quick!",
        "title" => "Bravera",
        "sound" => "default",
        "badge" => "1"
      })
      |> Notification.put_priority(:high)
      |> Pigeon.FCM.push()
    end)
  end
end
