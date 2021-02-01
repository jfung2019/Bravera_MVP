defmodule OmegaBravera.Repo.Migrations.AddEmailPermissionToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :email_permissions, {:array, :string}, null: false, default: []
    end
  end
end
