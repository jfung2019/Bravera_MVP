defmodule OmegaBraveraWeb.UserChannel do
  use OmegaBraveraWeb, :channel
  alias OmegaBravera.Groups
  @group_channel_prefix "group_channel:"
  @user_channel_prefix "user_channel:"
  @view OmegaBraveraWeb.GroupView
  import Phoenix.View, only: [render_many: 3, render_one: 3]

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
    # Join our own user channel to get info on user that later needs to be processed
    socket.endpoint.subscribe(user_channel(user_id))

    # Grab group latest info for chats and subscribe to the chat channels for
    # forwarding messages, etc.
    groups = Groups.list_joined_partners_with_chat_messages(user_id)

    for %{id: group_id} <- groups do
      :ok = socket.endpoint.subscribe("#{@group_channel_prefix}#{group_id}")
    end

    push(socket, "joined_groups", %{
      groups: render_many(groups, @view, "show_group_with_messages.json")
    })

    {:noreply, socket}
  end

  def handle_info(%{event: "joined_group" = event, payload: %{id: group_id}}, socket) do
    group = Groups.list_joined_partner_with_chat_messages(group_id)
    push(socket, event, %{group: render_one(group, @view, "show_group_with_messages.json")})
    {:noreply, socket}
  end

  def handle_info(%{event: event, payload: payload}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  def handle_in("joined_groups", _payload, %{assigns: %{current_user: %{id: user_id}}} = socket) do
    groups = Groups.list_joined_partners_with_chat_messages(user_id)
    {:reply, {:ok, %{groups: render_many(groups, @view, "show_group.json")}}, socket}
  end

  def handle_in(
        "create_message",
        %{"message_params" => message_params},
        %{assigns: %{current_user: user}} = socket
      ) do
    # TODO: look into preloading user instead of this hack.
    case Groups.create_chat_message(Map.put(message_params, "user_id", user.id)) do
      {:ok, message} ->
        socket.endpoint.broadcast("#{@group_channel_prefix}#{message.group_id}", "new_message", %{
          message: @view.render("show_message.json", message: %{message | user: user})
        })

        {:noreply, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def user_channel(user_id), do: "#{@user_channel_prefix}#{user_id}"

  # Add authorization logic here as required.
  defp authorized?(string_user_id, user_id), do: String.to_integer(string_user_id) == user_id
end
