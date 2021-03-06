defmodule OmegaBravera.Accounts.Friend do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, only: [:receiver_id, :requester_id, :status]}
  schema "friends" do
    belongs_to :receiver, User
    belongs_to :requester, User
    field :status, Ecto.Enum, values: [:accepted, :pending], default: :pending
    field :receiver_muted, :utc_datetime
    field :requester_muted, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(friend, attrs) do
    friend
    |> cast(attrs, [:receiver_id, :requester_id, :status])
    |> validate_required([:receiver_id, :requester_id, :status])
    |> validate_inclusion(:status, Ecto.Enum.values(__MODULE__, :status))
    |> check_constraint(:user_id, name: :cannot_friend_self)
    |> unique_constraint(:user_id, name: :friends_receiver_id_requester_id_index)
  end

  def request_changeset(friend, attrs) do
    changeset(friend, attrs)
    |> put_change(:status, :pending)
  end

  def accept_changeset(friend, attrs) do
    changeset(friend, attrs)
    |> put_change(:status, :accepted)
  end

  def mute_receiver_changeset(friend, attrs) do
    friend |> cast(attrs, [:receiver_muted])
  end

  def mute_requester_changeset(friend, attrs) do
    friend |> cast(attrs, [:requester_muted])
  end
end
