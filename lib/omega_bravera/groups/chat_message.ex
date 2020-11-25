defmodule OmegaBravera.Groups.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :message, :user_id, :group_id]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "group_chat_messages" do
    field :message, :string
    embeds_one :meta_data, OmegaBravera.Groups.ChatMessageMetaData, on_replace: :update
    belongs_to :reply_to_message, __MODULE__, type: :binary_id
    belongs_to :user, OmegaBravera.Accounts.User
    belongs_to :group, OmegaBravera.Groups.Partner

    timestamps()
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:message, :reply_to_message_id, :user_id, :group_id])
    |> cast_embed(:meta_data, required: true)
    |> validate_required([:message, :user_id, :group_id])
  end

  @doc false
  def update_changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [])
    |> cast_embed(:meta_data,
      required: true,
      with: &OmegaBravera.Groups.ChatMessageMetaData.update_changeset/2
    )
  end
end
