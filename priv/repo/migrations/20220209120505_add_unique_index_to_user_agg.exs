defmodule OmegaBravera.Repo.Migrations.AddUniqueIndexToUserAgg do
  use Ecto.Migration

  def change do
    create unique_index("user_agg", [:user_id])
  end
end
