defmodule OmegaBravera.Repo.Migrations.AddMDistanceToDonation do
  use Ecto.Migration

  def change do
    alter table(:donations) do
      add(:milestone_distance, :integer)
    end
  end
end
