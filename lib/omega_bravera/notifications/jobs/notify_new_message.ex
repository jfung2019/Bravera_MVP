defmodule OmegaBravera.Notifications.Jobs.NotifyNewMessage do
  @moduledoc """
  Check for new messages in chat and send a push notification to them
  """
  use Oban.Worker, queue: :default, max_attempts: 1
  alias OmegaBravera.{Notifications, Notifications.Jobs.Helper}

  @impl Oban.Worker
  def perform(
        %{"id" => message_id, "from_user_id" => from_user_id, "to_user_id" => to_user_id},
        _job
      ) do
    friend = OmegaBravera.Accounts.find_existing_friend(from_user_id, to_user_id)

    cond do
      friend.requester_id == to_user_id and is_nil(friend.requester_muted) ->
        notify_private_message(message_id, to_user_id)

      friend.receiver_id == to_user_id and is_nil(friend.receiver_muted) ->
        notify_private_message(message_id, to_user_id)

      true ->
        nil
    end

    :ok
  end

  def perform(%{"id" => message_id}, _job) do
    message = OmegaBravera.Groups.get_chat_message_with_group!(message_id)

    Notifications.list_notification_devices_with_new_message(message_id)
    |> Enum.each(&Helper.send_notification(&1, format_message(message), message.group.name))

    :ok
  end

  defp format_message(%{meta_data: %{message_type: :image}}), do: "Image"

  defp format_message(%{message: message}), do: message

  defp notify_private_message(message_id, to_user_id) do
    message = OmegaBravera.Accounts.get_private_message!(message_id)

    Notifications.list_notification_devices_by_user_id(to_user_id)
    |> Enum.each(
      &Helper.send_notification(&1, format_message(message), message.from_user.username)
    )
  end
end
