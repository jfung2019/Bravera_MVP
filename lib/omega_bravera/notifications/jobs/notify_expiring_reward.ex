defmodule OmegaBravera.Notifications.Jobs.NotifyExpiringReward do
  @moduledoc """
  Checks for any expiring rewards within the next 3, 7 or 14 days and
  sends a push notification to them.
  """
  use Oban.Worker, queue: :notification, max_attempts: 1
  alias OmegaBravera.{Notifications, Notifications.Jobs.Helper}

  @impl Oban.Worker
  def perform(_args, _job) do
    message = "A reward you 'own' expires soon! The clock is ticking ... claim it quick!"

    Notifications.list_notification_devices_with_expiring_offer_redeem(14)
    |> Enum.each(&Helper.send_notification(&1, message))

    :ok
  end
end
