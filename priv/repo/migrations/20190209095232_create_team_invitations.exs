defmodule OmegaBravera.Repo.Migrations.CreateTeamInvitations do
  use Ecto.Migration

  def up do
    create table(:team_invitations) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :email, :string, null: false
      add :invitee_name, :string, null: false
      add :status, :string, default: "pending_acceptance"

      timestamps(type: :timestamptz)
    end

    alter table("teams") do
      remove :invite_tokens
      remove :sent_invite_tokens
      remove :invitations_accepted
    end
  end

  def down do
    drop table(:team_invitations)

    alter table("teams") do
      add :invite_tokens, {:array, :string}
      add :sent_invite_tokens, {:array, :string}
    end
  end
end
