defmodule OmegaBravera.Repo.Migrations.AlterVendorEmailField do
  use Ecto.Migration

  def up do
    alter table("offer_vendors") do
      add :cc, :text
    end
  end

  def down do
    alter table("offer_vendors") do
      remove :cc
    end
  end
end
