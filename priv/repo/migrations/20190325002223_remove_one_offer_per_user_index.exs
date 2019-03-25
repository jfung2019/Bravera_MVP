defmodule OmegaBravera.Repo.Migrations.RemoveOneOfferPerUserIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:offer_challenges, [:user_id, :offer_id], name: :one_offer_per_user_index))
  end
end
