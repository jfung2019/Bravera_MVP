defmodule OmegaBravera.Repo.Migrations.ActivityAddAdminId do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      modify(:strava_id, :integer, null: true)
      add(:admin_id, :integer, default: nil)
    end

    create(
      constraint("activities", :strava_id_or_admin_id_required,
        check: "(admin_id IS NOT NULL) OR (strava_id IS NOT NULL)"
      )
    )
  end
end
