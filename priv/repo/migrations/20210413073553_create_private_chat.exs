defmodule OmegaBravera.Repo.Migrations.CreatePrivateChat do
  use Ecto.Migration

  def change do
    create table(:private_chat_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :message, :text, null: false
      add :meta_data, :map, null: false, default: %{}

      add :reply_to_message_id,
          references(:private_chat_messages, on_delete: :delete_all, type: :binary_id)

      add :from_user_id, references(:users, on_delete: :delete_all), null: false
      add :to_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:private_chat_messages, [:reply_to_message_id])
    create index(:private_chat_messages, [:from_user_id])
    create index(:private_chat_messages, [:to_user_id])
  end
end
