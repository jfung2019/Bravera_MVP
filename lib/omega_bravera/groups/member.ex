defmodule OmegaBravera.Groups.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "partner_members" do
    field :mute_notification, :utc_datetime

    belongs_to :user, OmegaBravera.Accounts.User
    belongs_to :partner, OmegaBravera.Groups.Partner

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :partner_id])
    |> validate_required([:user_id, :partner_id])
    |> unique_constraint(:user_id, name: :partner_members_user_id_partner_id_index)
  end

  def mute_notification_changeset(member, attrs) do
    member |> cast(attrs, [:mute_notification])
  end
end
