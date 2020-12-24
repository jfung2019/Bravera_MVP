defmodule OmegaBraveraWeb.Kaffy.GroupAdmin do
  import Ecto.Query

  def singular_name(_schema), do: "Group"

  def plural_name(_schema), do: "Groups"

  def custom_index_query(%{assigns: %{partner_user: %{id: user_id}}} = _conn, _schema, query),
    do: from(p in query, where: p.partner_user_id == ^user_id)

  def render_live(p) do
    if p.live do
      "✅"
    else
      "❌"
    end
  end

  def index(_schema) do
    [
      id: nil,
      name: %{name: "Group Name"},
      join_password: %{name: "Password to join"},
      email: %{name: "Email contact details"},
      live: %{value: &render_live/1}
    ]
  end

  def form_fields(_schema) do
    [
      name: %{label: "Group Name"},
      short_description: %{
        type: :richtext,
        help_text: "(displayed on list of groups in the Bravera app. 5-10 words)"
      },
      introduction: %{
        type: :richtext,
        help_text: "(Longer introduction when people click to find out more. Up to 250 words) "
      },
      join_password: %{
        label: "Password",
        help_text: "(leave blank if you want a public / open group. Click here for more info)"
      },
      email: %{label: "Email contact details", help_text: "(add if your group is private)"}
    ]
  end
end
