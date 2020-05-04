defmodule OmegaBravera.Repo.Migrations.AddPushNotificationBoolToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :push_notifications, :boolean, default: false, null: false
    end
  end
end
