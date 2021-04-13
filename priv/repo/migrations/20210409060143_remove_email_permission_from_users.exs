defmodule OmegaBravera.Repo.Migrations.RemoveEmailPermissionFromUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      remove :email_permissions
    end
  end
end
