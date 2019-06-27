defmodule OmegaBravera.Repo.Migrations.CreateNgoChallengeActivitiesM2m do
  use Ecto.Migration

  def up do
    create table(:ngo_challenge_activities_m2m, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:activity_id, references(:activities_accumulator, on_delete: :delete_all))
      add(:challenge_id, references(:ngo_chals, on_delete: :delete_all))
    end

    create(index(:ngo_challenge_activities_m2m, :id))
    create(unique_index(:ngo_challenge_activities_m2m, [:challenge_id, :activity_id], [name: :one_activity_instance_per_ngo_challenge]))
  end

  def down do
    drop(table(:ngo_challenge_activities_m2m))
  end
end

