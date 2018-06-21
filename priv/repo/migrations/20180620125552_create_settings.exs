defmodule OmegaBravera.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :email_notifications, :boolean, default: false, null: false
      add :location, :string
      add :show_lastname, :boolean, default: false, null: false
      add :request_delete, :boolean, default: false, null: false
      add :facebook, :string
      add :twitter, :string
      add :instagram, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :timestamptz)
    end

    create unique_index(:settings, [:user_id])
  end
end
