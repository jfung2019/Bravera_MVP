defmodule OmegaBravera.Repo.Migrations.RemoveDurationAndDurationsFromOffer do
  use Ecto.Migration

  def change do
    alter table("offers") do
      remove(:durations)
    end

    alter table("offer_challenges") do
      remove(:duration)
    end
  end
end
