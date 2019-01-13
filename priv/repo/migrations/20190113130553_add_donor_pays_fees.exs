defmodule OmegaBravera.Repo.Migrations.AddDonorPaysFees do
  use Ecto.Migration

  def change do
    alter table(:donations) do
      add :donor_pays_fees, :boolean, null: false, default: false
    end
  end
end
