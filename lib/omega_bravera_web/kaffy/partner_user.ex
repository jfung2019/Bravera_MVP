defmodule OmegaBravera.Kaffy.PartnerUser do
  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBravera.Accounts.PartnerUser
  import Ecto.Query

  def singular_name(_schema), do: "Partner User"

  def custom_index_query(%{assigns: %{partner_user: %{id: user_id}}} = _conn, _schema, query),
    do: from(p in query, where: p.id == ^user_id)

  def update_changeset(partner_user, attrs), do: PartnerUser.update_changeset(partner_user, attrs)

  def index(_schema) do
    [
      id: nil,
      email: nil,
      username: nil
    ]
  end

  def form_fields(_schema) do
    [
      username: nil,
      email: nil,
      business_type: nil,
      password: %{type: :password, help_text: "Leave blank to not change"}
    ]
  end

  def custom_links(_schema) do
    [
      %{
        name: "Logout",
        url: Routes.partner_user_session_path(OmegaBraveraWeb.Endpoint, :delete),
        method: :delete,
        order: 2,
        location: :top,
        icon: "sign-out-alt"
      }
    ]
  end
end
