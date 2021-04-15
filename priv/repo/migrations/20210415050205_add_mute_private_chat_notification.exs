defmodule OmegaBravera.Repo.Migrations.AddMutePrivateChatNotification do
  use Ecto.Migration

  def change do
    alter table("friends") do
      add :receiver_muted, :utc_datetime
      add :requester_muted, :utc_datetime
    end
  end
end
