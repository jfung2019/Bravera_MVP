defmodule OmegaBravera.Repo.Migrations.CreateOfferVendors do
  use Ecto.Migration

  def change do
    create table(:offer_vendors) do
      add :vendor_id, :string

      timestamps(type: :timestamptz)
    end

    create unique_index(:offer_vendors, [:vendor_id])

    alter table("offers") do
      add :vendor_id, :id
    end
  end
end
