defmodule OmegaBravera.Repo.Migrations.MakeDeviceTokenUniquePerUser do
  use Ecto.Migration

  def change do
    create unique_index(:notification_devices, [:token, :user_id])
  end
end
