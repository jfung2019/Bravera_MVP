defmodule OmegaBraveraWeb.PrivateChatView do
  use OmegaBraveraWeb, :view

  def render("show_friend_with_messages.json", %{friend: friend}) do
    %{
      id: friend.id,
      username: friend.username,
      image: friend.profile_picture,
      chat_messages:
        Phoenix.View.render_many(friend.private_chat_messages, __MODULE__, "show_message.json",
          as: :message
        )
    }
  end

  def render("show_message.json", %{message: %OmegaBravera.Accounts.PrivateChatMessage{} = message}) do
    %{
      id: message.id,
      message: message.message,
      from_user:
        Phoenix.View.render_one(message.from_user, OmegaBraveraWeb.GroupView, "show_user.json", as: :user),
      to_user:
        Phoenix.View.render_one(message.to_user, OmegaBraveraWeb.GroupView, "show_user.json", as: :user),
      reply_to_message:
        Phoenix.View.render_one(message.reply_to_message, __MODULE__, "show_message.json",
          as: :message
        ),
      meta_data:
        Phoenix.View.render_one(message.meta_data, OmegaBraveraWeb.GroupView, "show_meta_data.json",
          as: :meta_data
        ),
      inserted_at: message.inserted_at,
      updated_at: message.updated_at
    }
  end

  def render("show_message.json", %{message: _message}), do: nil
end
