defmodule OmegaBravera.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    field(:active, :boolean, default: false)
    field(:uuid, :string)

    belongs_to(:user, OmegaBravera.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:uuid, :active, :user_id])
    |> validate_required([:uuid, :active, :user_id])
    |> unique_constraint(:uuid, name: :device_exists_for_user)
  end
end
