defmodule OmegaBravera.Notifications.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification_devices" do
    field :token, :string
    belongs_to :user, OmegaBravera.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:token, :user_id])
    |> validate_required([:token, :user_id])
    |> unique_constraint(:token, name: :notification_devices_token_user_id_index)
  end
end
