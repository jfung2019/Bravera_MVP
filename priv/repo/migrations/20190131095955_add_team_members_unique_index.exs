defmodule OmegaBravera.Repo.Migrations.AddTeamMembersUniqueIndex do
  use Ecto.Migration

  def change do
    create(unique_index(:team_members, [:team_id, :user_id]))
  end
end
