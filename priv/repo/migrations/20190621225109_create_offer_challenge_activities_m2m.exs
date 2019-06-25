defmodule OmegaBravera.Repo.Migrations.CreateOfferChallengeActivitiesM2m do
  use Ecto.Migration

  def up do
    create table(:offer_challenge_activities_m2m, primary_key: false) do
      add(:activity_id, references(:activities_accumulator, on_delete: :delete_all))
      add(:offer_challenge_id, references(:offer_challenges, on_delete: :delete_all))
    end

    create(unique_index(:offer_challenge_activities_m2m, [:offer_challenge_id, :activity_id]))
  end

  def down do
    drop(table(:offer_challenge_activities_m2m))
  end
end

