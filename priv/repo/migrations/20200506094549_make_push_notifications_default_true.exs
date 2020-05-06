defmodule OmegaBravera.Repo.Migrations.MakePushNotificationsDefaultTrue do
  use Ecto.Migration

  def change do
    alter table("users") do
      modify :push_notifications, :boolean, default: true, null: false
    end
  end
end
