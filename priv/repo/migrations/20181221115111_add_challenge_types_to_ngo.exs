defmodule OmegaBravera.Repo.Migrations.AddChallengeTypesToNgo do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add :challenge_types, {:array, :string}, null: false, default: fragment("ARRAY['PER_KM', 'PER_MILESTONE']")
    end
  end
end
