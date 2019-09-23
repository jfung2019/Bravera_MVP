defmodule OmegaBravera.Repo.Migrations.CreateReferrals do
  use Ecto.Migration

  def change do
    create table(:referrals) do
      add(:status, :string)
      add(:token, :string)
      add(:bonus_points, :integer)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:referred_user_id, references(:users, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:referrals, [:user_id]))
    create(index(:referrals, [:referred_user_id]))
  end
end
