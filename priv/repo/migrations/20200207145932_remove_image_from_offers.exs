defmodule OmegaBravera.Repo.Migrations.RemoveImageFromOffers do
  use Ecto.Migration

  def change do
    alter table("offers") do
      remove(:image)
    end
  end
end
