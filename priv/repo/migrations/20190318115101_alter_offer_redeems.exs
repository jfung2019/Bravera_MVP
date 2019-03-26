defmodule OmegaBravera.Repo.Migrations.AlterOfferRedeems do
  use Ecto.Migration

  def change do
    alter table("offer_redeems") do
      remove(:vendor_id)
      add(:vendor_id, references(:offer_vendors, on_delete: :nothing))
    end
  end
end
