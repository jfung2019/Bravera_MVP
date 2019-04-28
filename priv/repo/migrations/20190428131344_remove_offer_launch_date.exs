defmodule OmegaBravera.Repo.Migrations.RemoveOfferLaunchDate do
  use Ecto.Migration

  def up do
    alter table("offers") do
      remove :launch_date
      add :always, :boolean, default: false
    end
  end

  def down do
    alter table("offers") do
      add :launch_date, :utc_datetime
      remove :always
    end
  end
end
