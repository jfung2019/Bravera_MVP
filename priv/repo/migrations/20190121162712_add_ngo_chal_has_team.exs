defmodule OmegaBravera.Repo.Migrations.AddNgoChalHasTeam do
  use Ecto.Migration

  def change do
    alter table("ngo_chals") do
      add(:has_team, :boolean, default: false, null: false)
    end
  end
end
