defmodule OmegaBravera.Repo.Migrations.AlterOfferDistances do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add(:target, :bigint)
    end

    alter table("activities_accumulator") do
      add(:segment_efforts, :map)
    end

    execute("update offers set target = distances[array_upper(distances, 1)]")

    flush()

    alter table("offers") do
      remove(:distances)
    end

    alter table("activities_accumulator") do
      remove(:segment_efforts)
    end
  end
end
