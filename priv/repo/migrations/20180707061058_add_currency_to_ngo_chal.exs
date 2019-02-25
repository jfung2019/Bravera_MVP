defmodule OmegaBravera.Repo.Migrations.AddCurrencyToNgoChal do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      add(:default_currency, :string)
    end
  end
end
