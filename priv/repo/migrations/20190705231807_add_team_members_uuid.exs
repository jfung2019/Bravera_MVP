defmodule OmegaBravera.Repo.Migrations.AddTeamMembersUuid do
  use Ecto.Migration

  def up do
    alter table("offer_team_members") do
      add(:id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()"))
    end

    alter table("team_members") do
      add(:id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()"))
    end
  end

  def down do
    alter table("offer_team_members") do
      remove(:id)
    end

    alter table("team_members") do
      remove(:id)
    end
  end
end
