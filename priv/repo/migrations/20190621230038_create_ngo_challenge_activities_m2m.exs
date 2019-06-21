defmodule OmegaBravera.Repo.Migrations.CreateNgoChallengeActivitiesM2m do
  use Ecto.Migration

  def up do
    create table(:ngo_challenge_activities_m2m, primary_key: false) do
      add(:user_id, references(:users))
      add(:activity_id, references(:activities_accumulator, on_delete: :delete_all))
      add(:challenge_id, references(:ngo_chals, on_delete: :delete_all))
    end

    create(unique_index(:ngo_challenge_activities_m2m, [:challenge_id, :user_id, :activity_id]))
  end

  def down do
    drop(table(:ngo_challenge_activities_m2m))
  end
end

