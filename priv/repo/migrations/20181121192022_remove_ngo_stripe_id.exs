defmodule OmegaBravera.Repo.Migrations.RemoveNgoStripeId do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      remove(:stripe_id)
    end
  end
end
