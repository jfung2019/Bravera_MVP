defmodule OmegaBravera.Repo.Migrations.CreateAdminUsers do
  use Ecto.Migration

  def change do
    create table(:admin_users) do
      add(:email, :string, null: false)
      add(:password_hash, :string, null: false)

      timestamps()
    end

    create(unique_index(:admin_users, [:email]))
  end
end
