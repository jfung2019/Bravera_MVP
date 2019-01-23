defmodule OmegaBravera.Repo.Migrations.AddTeamCount do
  use Ecto.Migration

  def change do
    alter table("teams") do
      add :count, :integer, default: 0, null: false
    end
  end
end
