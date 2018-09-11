defmodule OmegaBravera.Repo.Migrations.AddChargedFieldsToDonation do
  use Ecto.Migration

  def change do
    alter table("donations") do
      add :charge_id, :string
      add :last_digits, :string
      add :card_brand, :string
      add :charged_description, :string
      add :charged_status, :string
      add :charged_amount, :decimal
      add :charged_at, :utc_datetime
    end
  end
end
