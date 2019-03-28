defmodule OmegaBravera.Repo.Migrations.CreateOfferRewards do
  use Ecto.Migration

  def change do
    create table(:offer_rewards) do
      add(:name, :string)
      add(:value, :integer)
      add(:offer_id, references(:offers, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    alter table("offers") do
      remove(:reward_value)
    end

    create(index(:offer_rewards, [:offer_id]))
  end
end
