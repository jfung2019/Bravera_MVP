defmodule OmegaBraveraWeb.GroupView do
  use OmegaBraveraWeb, :view

  def render("show_group.json", %{group: group}) do
    %{id: group.id, name: group.name, image: List.first(group.images)}
  end

  def render("show_group_with_messages.json", %{group: group}) do
    %{
      id: group.id,
      name: group.name,
      image: List.first(group.images),
      is_muted: group.is_muted,
      chat_messages:
        Phoenix.View.render_many(group.chat_messages, __MODULE__, "show_message.json",
          as: :message
        ),
      users: Phoenix.View.render_many(group.users, __MODULE__, "show_user.json", as: :user)
    }
  end

  def render("show_message.json", %{message: %OmegaBravera.Groups.ChatMessage{} = message}) do
    %{
      id: message.id,
      user: Phoenix.View.render_one(message.user, __MODULE__, "show_user.json", as: :user),
      group_id: message.group_id,
      message: message.message,
      reply_to_message:
        Phoenix.View.render_one(message.reply_to_message, __MODULE__, "show_message.json",
          as: :message
        ),
      meta_data:
        Phoenix.View.render_one(message.meta_data, __MODULE__, "show_meta_data.json",
          as: :meta_data
        ),
      inserted_at: message.inserted_at,
      updated_at: message.updated_at
    }
  end

  def render("show_message.json", %{message: _message}), do: nil

  def render("show_meta_data.json", %{meta_data: meta_data}) do
    %{likes: meta_data.likes, emoji: meta_data.emoji, message_type: meta_data.message_type}
  end

  def render("show_user.json", %{user: user}) do
    %{id: user.id, username: user.username, profile_picture: user.profile_picture}
  end
end
