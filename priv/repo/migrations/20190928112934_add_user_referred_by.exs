defmodule OmegaBravera.Repo.Migrations.AddUserReferredBy do
  use Ecto.Migration

  def change do
    alter table("referrals") do
      remove(:referred_user_id)
    end

    alter table("users") do
      add(:referred_by_id, references(:users, on_delete: :nothing))
    end
  end
end
