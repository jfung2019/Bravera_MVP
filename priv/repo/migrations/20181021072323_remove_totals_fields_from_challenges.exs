defmodule OmegaBravera.Repo.Migrations.RemoveTotalsFieldsFromChallenges do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      remove :total_pledged
      remove :total_secured
    end
  end
end
