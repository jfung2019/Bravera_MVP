defmodule OmegaBravera.Notifications.Jobs.NotifyNewMessage do
  @moduledoc """
  Check for new messages in chat and send a push notification to them
  """
  use Oban.Worker, queue: :notification, max_attempts: 1
  alias OmegaBravera.{Notifications, Notifications.Jobs.Helper}

  @impl Oban.Worker
  def perform(%{"id" => message_id}, _job) do
    message = OmegaBravera.Groups.get_chat_message_with_group!(message_id)

    Notifications.list_notification_devices_with_new_message(message_id)
    |> Enum.each(&Helper.send_notification(&1, format_message(message), message.group.name))

    :ok
  end

  defp format_message(%{meta_data: %{message_type: :image}}), do: "Image"

  defp format_message(%{message: message}), do: message
end
