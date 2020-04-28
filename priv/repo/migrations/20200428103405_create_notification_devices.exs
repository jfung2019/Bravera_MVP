defmodule OmegaBravera.Repo.Migrations.CreateNotificationDevices do
  use Ecto.Migration

  def change do
    create table(:notification_devices) do
      add :token, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notification_devices, [:user_id])
  end
end
