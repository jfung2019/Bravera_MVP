defmodule OmegaBravera.Repo.Migrations.CreateOfferChallengeTeams do
  use Ecto.Migration

  def change do
    create table(:offer_challenge_teams) do
      add(:name, :string)
      add(:slug, :string, null: false)
      add(:count, :integer, default: 0, null: false)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:offer_challenge_id, references(:offer_challenges, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    flush()

    create(unique_index(:offer_challenge_teams, [:slug]))

    # Each team can only belong to a single offer_challenge.
    create(unique_index(:offer_challenge_teams, [:offer_challenge_id]))
  end
end
