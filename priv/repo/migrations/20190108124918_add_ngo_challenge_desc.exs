defmodule OmegaBravera.Repo.Migrations.AddNgoChallengeDesc do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add :challenge_desc, :text, default: nil
    end
  end
end
