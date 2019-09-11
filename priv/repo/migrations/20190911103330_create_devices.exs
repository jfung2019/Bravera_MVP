defmodule OmegaBravera.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add(:uuid, :string)
      add(:active, :boolean, default: false, null: false)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps(type: :timestamptz)
    end

    create(index(:devices, [:user_id]))
    create(unique_index(:devices, [:uuid], name: :device_exists_in_db))
  end
end
