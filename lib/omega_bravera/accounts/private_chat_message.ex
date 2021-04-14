defmodule OmegaBravera.Accounts.PrivateChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :message, :from_user_id, :to_user_id]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "private_chat_messages" do
    field :message, :string
    embeds_one :meta_data, OmegaBravera.Groups.ChatMessageMetaData, on_replace: :update
    belongs_to :reply_to_message, __MODULE__, type: :binary_id
    belongs_to :from_user, OmegaBravera.Accounts.User
    belongs_to :to_user, OmegaBravera.Accounts.User

    timestamps()
  end

  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:message, :reply_to_message_id, :from_user_id, :to_user_id])
    |> cast_embed(:meta_data, required: true)
    |> validate_required([:message, :from_user_id, :to_user_id])
  end

  def update_changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [])
    |> cast_embed(:meta_data,
      required: true,
      with: &OmegaBravera.Groups.ChatMessageMetaData.update_changeset/2
    )
  end
end
