defmodule OmegaBravera.Repo.Migrations.AddRoleToAdminUsers do
  use Ecto.Migration

  def change do
    alter table(:admin_users) do
      add :role, :string, default: "super", null: false
    end
  end
end
