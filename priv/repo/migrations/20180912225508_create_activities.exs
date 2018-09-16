defmodule OmegaBravera.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table("activities") do
      add :strava_id, :int, null: false
      add :name, :string
      add :distance, :decimal, null: false
      add :start_date, :timestamp
      add :manual, :boolean
      add :type, :string

      add :user_id, references("users"), null: false
      add :challenge_id, references("ngo_chals"), null: false

      timestamps()
    end
  end
end
