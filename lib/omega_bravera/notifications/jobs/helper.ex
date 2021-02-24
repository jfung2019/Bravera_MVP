defmodule OmegaBravera.Notifications.Jobs.Helper do
  alias OmegaBravera.{Notifications, Notifications.Device}
  alias Pigeon.FCM.Notification

  def send_notification(%Device{id: device_id, token: token}, message) do
    token
    |> Notification.new(%{
      "body" => message,
      "title" => "Bravera",
      "sound" => "default",
      "badge" => "1"
    })
    |> Notification.put_priority(:high)
    |> Pigeon.FCM.push()
    |> handle_fcm_push_result(device_id)
  end

  defp handle_fcm_push_result(%Notification{response: [invalid_registration: _token]}, device_id),
    do: delete_notification_device(device_id)

  defp handle_fcm_push_result(%Notification{response: [not_registered: _token]}, device_id),
    do: delete_notification_device(device_id)

  defp handle_fcm_push_result(_notification, _device_id), do: :ok

  defp delete_notification_device(id) do
    Notifications.get_device!(id)
    |> Notifications.delete_device()
  end
end
