defmodule OmegaBravera.Repo.Migrations.SettingWeightToDecimal do
  use Ecto.Migration

  def change do
    alter table("settings") do
      modify(:weight, :decimal)
    end
  end
end
