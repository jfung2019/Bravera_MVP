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
        Phoenix.View.render_many(group.chat_messages, __MODULE__, "show_message.json")
    }
  end

  def render("show_message.json", %{message: message}) do
    user = message.user

    %{
      id: message.id,
      user: %{id: user.id, username: user.username, profile_picture: user.profile_picture},
      group_id: message.group_id,
      message: message.message
    }
  end
end
