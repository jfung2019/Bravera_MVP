defmodule OmegaBravera.Repo.Migrations.AddIndexToPointsInsertedAt do
  use Ecto.Migration

  def change do
    create index("points", [:user_id, :inserted_at])
    create index("activities_accumulator", [:user_id, :start_date])
  end
end
