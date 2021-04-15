defmodule OmegaBravera.Repo.Migrations.CreateDeletePrivateMessageNotify do
  use Ecto.Migration

  def change do
    execute """
            CREATE OR REPLACE FUNCTION notify_private_chat_message_deleted()
            RETURNS trigger AS $$
            BEGIN
            PERFORM pg_notify(
            'private_chat_message_deleted',
            json_build_object(
              'message', row_to_json(OLD)
            )::text
            );

            RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
            """,
            "DROP FUNCTION IF EXISTS notify_private_chat_message_deleted()"

    execute """
            CREATE TRIGGER notify_private_chat_message_deleted
            BEFORE DELETE
            ON private_chat_messages
            FOR EACH ROW
            EXECUTE PROCEDURE notify_private_chat_message_deleted()
            """,
            "DROP TRIGGER IF EXISTS notify_private_chat_message_deleted ON private_chat_messages"
  end
end
