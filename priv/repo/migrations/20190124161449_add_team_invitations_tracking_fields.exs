defmodule OmegaBravera.Repo.Migrations.AddTeamInvitationsTrackingFields do
  use Ecto.Migration

  def change do
    alter table("teams") do
      add(:invite_tokens, {:array, :string})
      add(:sent_invite_tokens, {:array, :string})
      add(:invitations_accepted, :integer, default: 0)
    end

    drop(unique_index(:teams, [:name]))
  end
end
