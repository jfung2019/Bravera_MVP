defmodule OmegaBravera.Repo.Migrations.AddPedometerAsSource do
  use Ecto.Migration

  def change do
    alter table("activities_accumulator") do
      add :step_count, :integer
    end
  end
end
