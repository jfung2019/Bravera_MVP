defmodule OmegaBravera.Repo.Migrations.FixDeleteMessageFunc do
  use Ecto.Migration

  def change do
    execute """
            CREATE OR REPLACE FUNCTION notify_private_chat_message_deleted()
            RETURNS trigger AS $$
            BEGIN
            PERFORM pg_notify(
            'private_chat_message_deleted',
            json_build_object(
              'message', json_build_object('id', OLD.id, 'from_user_id', OLD.from_user_id, 'to_user_id', OLD.to_user_id)
            )::text
            );

            RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
            """,
            "DROP FUNCTION IF EXISTS notify_private_chat_message_deleted()"
  end
end
