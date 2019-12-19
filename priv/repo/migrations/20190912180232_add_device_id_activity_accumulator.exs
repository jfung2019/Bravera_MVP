defmodule OmegaBravera.Repo.Migrations.AddDeviceIdActivityAccumulator do
  use Ecto.Migration

  def up do
    alter table("activities_accumulator") do
      add(:device_id, references("devices", on_delete: :delete_all))
      add(:end_date, :utc_datetime)
    end

    drop(constraint("activities_accumulator", :strava_id_or_admin_id_required))

    create(
      constraint("activities_accumulator", :strava_id_or_admin_id_or_device_id_required,
        check: "(admin_id IS NOT NULL) OR (strava_id IS NOT NULL) OR (device_id IS NOT NULL)"
      )
    )
  end

  def down do
    alter table("activities_accumulator") do
      remove(:device_id)
      remove(:end_date)
    end

    flush()

    drop(constraint("activities_accumulator", :strava_id_or_admin_id_or_device_id_required))

    create(
      constraint("activities_accumulator", :strava_id_or_admin_id_required,
        check: "(admin_id IS NOT NULL) OR (strava_id IS NOT NULL)"
      )
    )
  end
end
