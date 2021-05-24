defmodule OmegaBravera.Repo.Migrations.AddSyncTypeToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :sync_type, :varchar, default: "device", null: false
    end
  end
end
