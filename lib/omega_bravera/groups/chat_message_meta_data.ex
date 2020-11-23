defmodule OmegaBravera.Groups.ChatMessageMetaData do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :likes, {:array, :integer}, default: []
    field :emoji, :map, default: %{}
    field :message_type, Ecto.Enum, values: [:text, :image], default: :text
  end

  def changeset(meta, attrs) do
    meta
    |> cast(attrs, [:message_type])
    |> validate_required([:message_type])
    |> validate_inclusion(:message_type, Ecto.Enum.values(__MODULE__, :message_type))
  end

  def update_changeset(meta, attrs) do
    meta
    |> cast(attrs, [:likes, :emoji])
    |> validate_required([:likes, :emoji])
  end
end
