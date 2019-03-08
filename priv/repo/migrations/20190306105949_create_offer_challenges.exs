defmodule OmegaBravera.Repo.Migrations.CreateOfferChallenges do
  use Ecto.Migration

  def change do
    create table(:offer_challenges) do
      add(:activity_type, :string)
      add(:distance_target, :integer)
      add(:duration, :integer)
      add(:milestones, :integer)
      add(:default_currency, :string)
      add(:slug, :string)
      add(:start_date, :utc_datetime)
      add(:end_date, :utc_datetime)
      add(:status, :string)
      add(:last_activity_received, :utc_datetime)
      add(:type, :string)
      add(:has_team, :boolean, default: false, null: false)
      add(:participant_notified_of_inactivity, :boolean, default: false, null: false)
      add(:offer_id, references(:offers, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(unique_index(:offer_challenges, [:slug], name: :offer_challenges_slug_unique_index))
    create(unique_index(:offer_challenges, [:user_id, :offer_id], name: :one_offer_per_user_index))
    create(index(:offer_challenges, [:offer_id]))
    create(index(:offer_challenges, [:user_id]))
  end
end
