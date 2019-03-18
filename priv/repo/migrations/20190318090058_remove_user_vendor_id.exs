defmodule OmegaBravera.Repo.Migrations.RemoveUserVendorId do
  use Ecto.Migration

  def change do
    alter table("users") do
      remove(:vendor_id)
    end
  end
end
