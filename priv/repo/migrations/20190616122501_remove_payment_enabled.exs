defmodule OmegaBravera.Repo.Migrations.RemovePaymentEnabled do
  use Ecto.Migration

  def up do
    alter table(:offers) do
      remove :payment_enabled
      modify :payment_amount, :decimal, default: nil
    end
  end

  def down do
    alter table(:offers) do
      add :payment_enabled, :boolean, default: false
    end
  end

end
