defmodule OmegaBravera.Repo.Migrations.CreateGroupChatMessages do
  use Ecto.Migration

  def change do
    create table(:group_chat_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :message, :text, null: false
      add :meta_data, :map, null: false, default: %{}

      add :reply_to_message_id,
          references(:group_chat_messages, on_delete: :delete_all, type: :binary_id)

      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :group_id, references(:partners, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:group_chat_messages, [:reply_to_message_id])
    create index(:group_chat_messages, [:user_id])
    create index(:group_chat_messages, [:group_id])
  end
end
