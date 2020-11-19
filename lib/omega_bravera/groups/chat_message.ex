defmodule OmegaBravera.Groups.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "group_chat_messages" do
    field :message, :string
    field :meta_data, :map, default: %{}
    belongs_to :reply_to_message, __MODULE__
    belongs_to :user, OmegaBravera.Accounts.User
    belongs_to :group, OmegaBravera.Groups.Partner

    timestamps()
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:message, :meta_data, :reply_to_message_id, :user_id, :group_id])
    |> validate_required([:message, :meta_data, :user_id, :group_id])
  end

  @doc false
  def update_changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:meta_data])
    |> validate_required([:meta_data])
  end
end
