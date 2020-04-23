defmodule OmegaBravera.Repo.Migrations.AddExpiryToOfferRedeems do
  use Ecto.Migration

  def change do
    alter table("offer_redeems") do
      add :expired_at, :utc_datetime
    end

    alter table("offers") do
      add :redemption_days, :integer
    end
  end
end
