defmodule OmegaBravera.Repo.Migrations.CreateChallengeSlugIndex do
  use Ecto.Migration

  def change do
    create index(:ngo_chals, [:ngo_id, :slug])
  end
end
