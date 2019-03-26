defmodule OmegaBravera.Repo.Migrations.CreateOfferRedeems do
  use Ecto.Migration

  def change do
    create table(:offer_redeems) do
      add(:offer_reward_id, references(:offer_rewards, on_delete: :nothing))
      add(:offer_id, references(:offers, on_delete: :nothing))
      add(:offer_challenge_id, references(:offer_challenges, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))
      add(:vendor_id, references(:users, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:offer_redeems, [:offer_reward_id]))
    create(index(:offer_redeems, [:offer_id]))
    create(index(:offer_redeems, [:offer_challenge_id]))
    create(index(:offer_redeems, [:user_id]))
  end
end
