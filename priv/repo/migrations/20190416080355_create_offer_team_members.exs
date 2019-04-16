defmodule OmegaBravera.Repo.Migrations.CreateOfferTeamMembers do
  use Ecto.Migration

  def up do
    # Many to many assoc offer_challenge_teams <- offer_team_members -> user
    create table(:offer_team_members, primary_key: false) do
      add(:user_id, references(:users))
      add(:team_id, references(:offer_challenge_teams))
    end

    create(unique_index(:offer_team_members, [:team_id, :user_id]))
  end

  def down do
    drop(table(:offer_team_members))
  end
end
