defmodule OmegaBravera.Repo.Migrations.AddOfferTimeLimit do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add(:time_limit, :integer, default: 0)
    end
  end
end
