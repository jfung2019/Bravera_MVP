defmodule OmegaBravera.Repo.Migrations.AddOfferTypeOnlineUrlOnlineCodeToOffers do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add :offer_type, :string, null: false, default: "in_store"
      add :online_url, :string
      add :online_code, :string
    end
  end
end
