defmodule OmegaBravera.Repo.Migrations.AddMoreStravaActivityFields do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add(:average_speed, :decimal, default: 0)
      add(:moving_time, :integer, default: 0)
      add(:elapsed_time, :integer, default: 0)
    end
  end
end
