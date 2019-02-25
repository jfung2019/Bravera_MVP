defmodule OmegaBravera.Repo.Migrations.TeamsAndUsersManyToManyTable do
  use Ecto.Migration

  def up do
    # Many to many assoc team <- team_members -> user
    create table(:team_members, primary_key: false) do
      add(:user_id, references(:users))
      add(:team_id, references(:teams))
    end
  end

  def down do
    drop(table(:team_members))
  end
end
