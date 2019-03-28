defmodule OmegaBravera.Repo.Migrations.AddUserVendorId do
  use Ecto.Migration

  def change do
    alter table("users") do
      add(:vendor_id, :string)
    end
  end
end
