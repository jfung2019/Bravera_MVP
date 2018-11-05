defmodule OmegaBravera.Repo.Migrations.RemoveDistanceCoveredFromChallenge do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      remove :distance_covered
    end
  end
end
