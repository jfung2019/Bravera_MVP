defmodule OmegaBravera.Repo.Migrations.CreateOfferChallengeTeamInvitations do
  use Ecto.Migration

  def up do
    create table(:offer_challenge_team_invitations) do
      add(:team_id, references(:offer_challenge_teams, on_delete: :delete_all),
        null: false
      )

      add(:token, :string, null: false)
      add(:email, :string, null: false)
      add(:invitee_name, :string, null: false)
      add(:status, :string, default: "pending_acceptance")

      timestamps(type: :timestamptz)
    end
  end

  def down do
    drop(table(:offer_challenge_team_invitations))
  end
end
