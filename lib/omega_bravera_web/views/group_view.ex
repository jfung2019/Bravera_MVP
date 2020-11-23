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
      chat_messages:
        Phoenix.View.render_many(group.chat_messages, __MODULE__, "show_message.json", as: :message),
      users: Phoenix.View.render_many(group.users, __MODULE__, "show_user.json", as: :user)
    }
  end

  def render("show_message.json", %{message: message}) do
    %{
      id: message.id,
      user: Phoenix.View.render_one(message.user, __MODULE__, "show_user.json", as: :user),
      group_id: message.group_id,
      message: message.message
    }
  end

  def render("show_user.json", %{user: user}) do
    %{id: user.id, username: user.username, profile_picture: user.profile_picture}
  end
end
