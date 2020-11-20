defmodule OmegaBraveraWeb.UserChannel do
  use OmegaBraveraWeb, :channel
  alias OmegaBravera.Groups
  @group_channel_prefix "group_channel:"

  @moduledoc """
  This channel is used to send notifications when users are connected
  over websocket.
  """

  def join(
        "user:" <> string_user_id,
        _payload,
        %{assigns: %{current_user: %{id: user_id}}} = socket
      ) do
    if authorized?(string_user_id, user_id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, %{assigns: %{current_user: %{id: user_id}}} = socket) do
    for %{id: group_id} <- Groups.list_joined_partners(user_id) do
      :ok = socket.endpoint.subscribe("#{@group_channel_prefix}#{group_id}")
    end
    {:noreply, socket}
  end

  def handle_info(%{event: event, payload: payload}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  def handle_in("joined_groups", _payload, %{assigns: %{current_user: %{id: user_id}}} = socket) do
    groups = Groups.list_joined_partners(user_id)
    {:reply, {:ok, %{groups: groups}}, socket}
  end

  def handle_in("create_message", %{"message_params" => message_params}, %{assigns: %{current_user: %{id: user_id}}} = socket) do
    case Groups.create_chat_message(Map.put(message_params, "user_id", user_id)) do
      {:ok, message} ->
        socket.endpoint.broadcast("#{@group_channel_prefix}#{message.group_id}", "new_message", %{message: message})
        {:noreply, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(string_user_id, user_id), do: String.to_integer(string_user_id) == user_id
end
