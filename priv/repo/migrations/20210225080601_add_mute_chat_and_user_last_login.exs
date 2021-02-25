defmodule OmegaBravera.Repo.Migrations.AddMuteChatAndUserLastLogin do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :last_login_datetime, :utc_datetime
    end

    alter table("partner_members") do
      add :mute_notification, :boolean, null: false, default: false
    end
  end
end
