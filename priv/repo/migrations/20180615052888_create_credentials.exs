defmodule OmegaBravera.Repo.Migrations.CreateCredentials do
  use Ecto.Migration

  def change do
    create table(:credentials) do
      add(:password_hash, :string)
      add(:reset_token, :string)
      add(:reset_token_created, :utc_datetime)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps(type: :timestamptz)
    end

    create(index(:credentials, [:user_id]))
  end
end
