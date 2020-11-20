defmodule OmegaBravera.Groups.ChatMessageMetaData do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
  end

  def changeset(meta, attrs) do
    meta
    |> cast(attrs, [])
  end
end
