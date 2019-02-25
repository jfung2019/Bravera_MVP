defmodule OmegaBravera.Repo.Migrations.DistanceTargetToInt do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      modify(:distance_target, :integer)
    end
  end
end
