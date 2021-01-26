defmodule OmegaBravera.Repo.Migrations.AddLiveToOffer do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add :live, :boolean, default: false, null: false
    end

    flush()

    execute "UPDATE offers SET live = 't' WHERE organization_id IS NULL", ""
    execute "UPDATE offers SET live = 'f' WHERE NOT(organization_id IS NULL)", ""
  end
end
