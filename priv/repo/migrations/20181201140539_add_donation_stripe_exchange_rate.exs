defmodule OmegaBravera.Repo.Migrations.AddDonationStripeExchangeRate do
  use Ecto.Migration

  def change do
    alter table(:donations) do
      add :exchange_rate, :float, default: 1.0
    end
  end
end
