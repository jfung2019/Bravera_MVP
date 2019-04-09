defmodule OmegaBravera.Repo.Migrations.AddVendorEmail do
  use Ecto.Migration

  def change do
    alter table("offer_vendors") do
      add(:email, :string)
    end
  end
end
