defmodule OmegaBravera.Repo.Migrations.UpdateDailyPointsLimit do
  use Ecto.Migration

  def change do
    execute("UPDATE users SET daily_points_limit = 8;")
  end
end
