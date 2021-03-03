defmodule OmegaBraveraWeb.UserChannel do
  use OmegaBraveraWeb, :channel
  alias OmegaBravera.{Groups, Accounts}
  alias OmegaBraveraWeb.Api.Resolvers.Helpers
  @group_channel_prefix "group_channel:"
  @user_channel_prefix "user_channel:"
  @view OmegaBraveraWeb.GroupView
  import Phoenix.View, only: [render_many: 3, render_one: 3, render_many: 4]

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

    group_ids =
      Enum.map(groups, fn %{id: group_id} ->
        :ok = socket.endpoint.subscribe("#{@group_channel_prefix}#{group_id}")
        group_id
      end)

    push(socket, "joined_groups", %{
      groups: render_many(groups, @view, "show_group_with_messages.json")
    })

    {:noreply, assign(socket, :group_ids, group_ids)}
  end

  def handle_info(
        %{event: "joined_group" = event, payload: %{id: group_id}},
        %{assigns: %{current_user: %{id: user_id}}} = socket
      ) do
    group = Groups.list_joined_partner_with_chat_messages(group_id, user_id)
    :ok = socket.endpoint.subscribe("#{@group_channel_prefix}#{group_id}")
    push(socket, event, %{group: render_one(group, @view, "show_group_with_messages.json")})
    {:noreply, assign(socket, :group_ids, [group_id | socket.assigns.group_ids])}
  end

  def handle_info(%{event: "removed_group" = event, payload: %{id: group_id}}, socket) do
    group = Groups.get_partner!(group_id)
    :ok = socket.endpoint.unsubscribe("#{@group_channel_prefix}#{group_id}")
    group_ids = Enum.reject(socket.assigns.group_ids, fn id -> id == group_id end)
    push(socket, event, %{group: render_one(group, @view, "show_group.json")})
    {:noreply, assign(socket, :group_ids, group_ids)}
  end

  def handle_info(%{event: event, payload: payload}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  def handle_in("delete_message", %{"message_id" => message_id}, socket) do
    Groups.get_chat_message!(message_id)
    |> Groups.delete_chat_message()

    {:noreply, socket}
  end

  def handle_in(
        "emoji_message",
        %{"message_id" => message_id, "emoji" => emoji},
        %{assigns: %{current_user: %{id: user_id}}} = socket
      ) do
    %{meta_data: %{emoji: emoji_map}} = message = Groups.get_chat_message!(message_id)
    user_ids = Map.get(emoji_map, emoji, [])

    emoji_map =
      cond do
        # at least this user, just remove the user, and keep others
        user_id in user_ids and length(user_ids) > 1 ->
          Map.put(emoji_map, emoji, Enum.reject(user_ids, fn u_id -> u_id == user_id end))

        # only this user
        user_id in user_ids and length(user_ids) == 1 ->
          Map.delete(emoji_map, emoji)

        # user doesn't currently emoji this
        true ->
          Map.put(emoji_map, emoji, [user_id | user_ids])
      end

    {:ok, message} = Groups.update_chat_message(message, %{meta_data: %{emoji: emoji_map}})

    socket.endpoint.broadcast("#{@group_channel_prefix}#{message.group_id}", "updated_message", %{
      message: @view.render("show_message.json", message: message)
    })

    {:noreply, socket}
  end

  def handle_in(
        "like_message",
        %{"message_id" => message_id},
        %{assigns: %{current_user: %{id: user_id}}} = socket
      ) do
    %{meta_data: %{likes: likes}} = message = Groups.get_chat_message!(message_id)

    likes =
      if user_id in likes do
        Enum.reject(likes, fn u_id -> u_id == user_id end)
      else
        [user_id | likes]
      end

    {:ok, message} = Groups.update_chat_message(message, %{meta_data: %{likes: likes}})

    socket.endpoint.broadcast("#{@group_channel_prefix}#{message.group_id}", "updated_message", %{
      message: @view.render("show_message.json", message: message)
    })

    {:noreply, socket}
  end

  def handle_in("joined_groups", _payload, %{assigns: %{current_user: %{id: user_id}}} = socket) do
    groups = Groups.list_joined_partners_with_chat_messages(user_id)

    {:reply, {:ok, %{groups: render_many(groups, @view, "show_group_with_messages.json")}},
     socket}
  end

  def handle_in(
        "create_message",
        %{"message_params" => %{"group_id" => group_id} = message_params},
        %{assigns: %{current_user: user, group_ids: group_ids}} = socket
      ) do
    if group_id in group_ids do
      case Groups.create_chat_message(Map.put(message_params, "user_id", user.id)) do
        {:ok, message} ->
          message =
            Groups.get_chat_message!(message.id)
            |> Groups.notify_new_message()

          socket.endpoint.broadcast(
            "#{@group_channel_prefix}#{message.group_id}",
            "new_message",
            %{
              message: @view.render("show_message.json", message: message)
            }
          )

          {:noreply, socket}

        {:error, changeset} ->
          {:reply, {:error, %{errors: Helpers.transform_errors(changeset)}}, socket}
      end
    else
      push(socket, "removed_group", %{group: %{id: group_id}})
      {:reply, {:error, %{errors: %{group_id: ["not allowed"]}}}, socket}
    end
  end

  def handle_in("unread_count", %{"message_ids" => message_ids}, socket) do
    unread_count =
      message_ids
      |> Enum.map(fn message_id ->
        {message_id, Groups.get_unread_group_message_count(message_id)}
      end)
      |> Enum.into(%{})

    {:reply, {:ok, %{unread_count: unread_count}}, socket}
  end

  def handle_in("previous_messages", %{"message_id" => message_id, "limit" => limit}, socket) do
    previous_messages = Groups.get_previous_messages(message_id, limit)

    {:reply,
     {:ok, %{messages: render_many(previous_messages, @view, "show_message.json", as: :message)}},
     socket}
  end

  def handle_in(
        "mute_notification",
        %{"group_id" => group_id},
        %{assigns: %{current_user: %{id: user_id}}} = socket
      ) do
    member = Groups.get_group_member_by_group_id_user_id(group_id, user_id)

    case Groups.group_member_mute_group(member, mute_group(member)) do
      {:ok, %{partner_id: partner_id, mute_notification: muted}} ->
        {:reply, {:ok, %{group_id: partner_id, muted: not is_nil(muted)}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: Helpers.transform_errors(changeset)}}, socket}
    end
  end

  def user_channel(user_id), do: "#{@user_channel_prefix}#{user_id}"

  # Add authorization logic here as required.
  defp authorized?(string_user_id, user_id), do: String.to_integer(string_user_id) == user_id

  def terminate(_reason, %{assigns: %{current_user: %{id: user_id}}}) do
    Accounts.get_user!(user_id)
    |> Accounts.update_user(%{last_login_datetime: Timex.now()})
  end

  def terminate(reason, _socket), do: reason

  defp mute_group(%{mute_notification: nil}), do: %{mute_notification: Timex.now()}

  defp mute_group(_member), do: %{mute_notification: nil}
end
