defmodule OmegaBravera.Repo.Migrations.CreateOfferChallengeActivities do
  use Ecto.Migration

  def change do
    create table(:offer_challenge_activities) do
      add(:admin_id, :integer, default: nil)
      add(:strava_id, :bigint, null: true)
      add(:name, :string)
      add(:distance, :decimal)
      add(:start_date, :utc_datetime)
      add(:manual, :boolean, default: false, null: false)
      add(:type, :string)
      add(:average_speed, :decimal)
      add(:moving_time, :integer)
      add(:elapsed_time, :integer)
      add(:calories, :decimal)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:offer_challenge_id, references(:offer_challenges, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:offer_challenge_activities, [:user_id]))
    create(index(:offer_challenge_activities, [:offer_challenge_id]))

    create(
      constraint("offer_challenge_activities", :strava_id_or_admin_id_required,
        check: "(admin_id IS NOT NULL) OR (strava_id IS NOT NULL)"
      )
    )
  end
end
