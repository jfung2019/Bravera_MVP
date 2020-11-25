defmodule OmegaBravera.Repo.Migrations.BroadcastDeletedChatMessages do
  use Ecto.Migration

  def change do
    execute """
            CREATE OR REPLACE FUNCTION notify_group_chat_message_deleted()
            RETURNS trigger AS $$
            BEGIN
            PERFORM pg_notify(
            'group_chat_message_deleted',
            json_build_object(
              'message', row_to_json(OLD)
            )::text
            );

            RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
            """,
            "DROP FUNCTION IF EXISTS notify_group_chat_message_deleted()"

    execute """
            CREATE TRIGGER notify_group_chat_message_deleted
            BEFORE DELETE
            ON group_chat_messages
            FOR EACH ROW
            EXECUTE PROCEDURE notify_group_chat_message_deleted()
            """,
            "DROP TRIGGER IF EXISTS notify_group_chat_message_deleted ON group_chat_messages"
  end
end
