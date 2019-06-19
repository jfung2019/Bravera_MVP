defmodule OmegaBravera.Repo.Migrations.CreateOfferChallengePayment do
  use Ecto.Migration

  def up do
    create table(:payments) do
      add(:amount, :decimal)
      add(:currency, :string)
      add(:status, :string)
      add(:stripe_token, :string)

      # charge successful adds
      add(:charge_id, :string)
      add(:last_digits, :string)
      add(:card_brand, :string)
      add(:charged_description, :string)
      add(:charged_status, :string)
      add(:charged_amount, :decimal)
      add(:charged_at, :utc_datetime)
      add(:exchange_rate, :decimal)

      add(:user_id, references(:users, on_delete: :nothing))
      add(:offer_challenge_id, references(:offer_challenges, on_delete: :nothing))
      add(:offer_id, references(:offers, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    alter table(:offers) do
      add(:payment_enabled, :boolean, default: false)
      add(:payment_amount, :decimal, default: nil)
    end

    create(unique_index(:payments, [:offer_challenge_id]))
  end

  def down do
    drop(table(:payments))

    alter table(:offers) do
      remove(:payment_enabled)
      remove(:payment_amount)
    end
  end
end
