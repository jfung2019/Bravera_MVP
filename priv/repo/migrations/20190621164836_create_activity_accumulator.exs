defmodule OmegaBravera.Repo.Migrations.CreateActivityAccumulator do
  use Ecto.Migration

  def up do
    create table(:activities_accumulator) do
      add(:admin_id, :integer, default: nil)
      add(:strava_id, :bigint, null: true)
      add(:name, :string)
      add(:distance, :decimal)
      add(:start_date, :utc_datetime)
      add(:manual, :boolean, default: false, null: false)
      add(:type, :string)
      add(:source, :string)
      add(:average_speed, :decimal)
      add(:moving_time, :integer)
      add(:elapsed_time, :integer)
      add(:calories, :decimal)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps(type: :timestamptz)
    end

    create(index(:activities_accumulator, [:user_id]))
    create(
      constraint("activities_accumulator", :strava_id_or_admin_id_required,
        check: "(admin_id IS NOT NULL) OR (strava_id IS NOT NULL)"
      )
    )
    create(unique_index(:activities_accumulator, [:strava_id]))
  end

  def down do
    drop table(:activities_accumulator)
  end
end
