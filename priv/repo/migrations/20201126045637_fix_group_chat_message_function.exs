defmodule OmegaBravera.Repo.Migrations.FixGroupChatMessageFunction do
  use Ecto.Migration

  def change do
    execute """
            CREATE OR REPLACE FUNCTION notify_group_chat_message_deleted()
            RETURNS trigger AS $$
            BEGIN
            PERFORM pg_notify(
            'group_chat_message_deleted',
            json_build_object(
              'message', json_build_object('id', OLD.id, 'group_id', OLD.group_id)
            )::text
            );

            RETURN OLD;
            END;
            $$ LANGUAGE plpgsql;
            """,
            """
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
            """
  end
end
