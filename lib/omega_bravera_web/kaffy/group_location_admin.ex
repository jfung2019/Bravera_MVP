defmodule OmegaBraveraWeb.Kaffy.GroupLocationAdmin do
  import Ecto.Query

  def singular_name(_schema), do: "Group Location"

  def plural_name(_schema), do: "Group Locations"

  def custom_index_query(%{assigns: %{partner_user: %{id: user_id}}} = _conn, _schema, query),
    do:
      from(l in query,
        join: p in assoc(l, :partner),
        where: p.partner_user_id == ^user_id,
        preload: [partner: p]
      )

  def index(_schema) do
    [
      id: nil,
      address: nil,
      partner_id: %{name: "Group", value: fn l -> l.partner.name end}
    ]
  end

  # TODO: override form_fields to use conn
  def form_fields(_schema) do
    [
      address: nil,
      latitude: nil,
      longitude: nil,
      partner_id: %{label: "Group"}
    ]
  end
end
