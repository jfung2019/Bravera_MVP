defmodule OmegaBravera.Repo.Migrations.AddDonationKmDistance do
  use Ecto.Migration

  def change do
    alter table(:donations) do
      add :km_distance, :integer, null: true, default: nil
    end
  end
end
