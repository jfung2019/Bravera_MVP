defmodule OmegaBravera.Repo.Migrations.AddUserDailyPointsLimit do
  use Ecto.Migration

  def up do
    alter table("users") do
      add(:daily_points_limit, :integer, default: 15)
    end
  end

  def down do
    alter table("users") do
      remove(:daily_points_limit)
    end
  end
end
