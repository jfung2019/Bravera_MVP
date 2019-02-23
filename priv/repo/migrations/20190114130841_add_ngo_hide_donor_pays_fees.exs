defmodule OmegaBravera.Repo.Migrations.AddNgoHideDonorPaysFees do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add(:hide_donor_pays_fees, :boolean, null: false, default: true)
    end
  end
end
