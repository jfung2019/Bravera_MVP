defmodule OmegaBravera.Repo.Migrations.AllowHideOfferReward do
  use Ecto.Migration

  def change do
    alter table(:offer_rewards) do
      add :hide, :boolean, null: false, default: false
    end
  end
end
