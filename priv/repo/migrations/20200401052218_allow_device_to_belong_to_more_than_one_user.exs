defmodule OmegaBravera.Repo.Migrations.AllowDeviceToBelongToMoreThanOneUser do
  use Ecto.Migration

  def change do
    drop unique_index(:devices, [:uuid], name: :device_exists_in_db)
    create unique_index(:devices, [:uuid, :user_id], name: :device_exists_for_user)
  end
end
