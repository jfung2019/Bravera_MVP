defmodule OmegaBravera.Repo.Migrations.AddMinimumDontationToNgos do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add(:minimum_donation, :integer, null: false, default: 0)
    end
  end
end
