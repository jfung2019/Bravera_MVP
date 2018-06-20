defmodule OmegaBravera.Accounts.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  schema "settings" do
    field :email_notifications, :boolean, default: false
    field :facebook, :string
    field :instagram, :string
    field :location, :string
    field :request_delete, :boolean, default: false
    field :show_lastname, :boolean, default: false
    field :twitter, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:email_notifications, :location, :show_lastname, :request_delete, :facebook, :twitter, :instagram])
    |> validate_required([:email_notifications, :location, :show_lastname, :request_delete, :facebook, :twitter, :instagram])
  end
end
