defmodule OmegaBravera.Repo.Migrations.RemoveOfferUserId do
  use Ecto.Migration

  def change do
    alter table("offers") do
      remove (:user_id)
    end
  end
end
