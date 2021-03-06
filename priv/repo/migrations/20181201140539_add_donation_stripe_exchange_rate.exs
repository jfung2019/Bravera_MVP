defmodule OmegaBravera.Repo.Migrations.AddDonationStripeExchangeRate do
  use Ecto.Migration

  def change do
    alter table(:donations) do
      add(:exchange_rate, :decimal, default: 1)
    end
  end
end
