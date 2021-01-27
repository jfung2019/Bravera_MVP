defmodule OmegaBravera.Repo.Migrations.RemoveLiveFromOffersGroups do
  use Ecto.Migration

  def change do
    alter table("offers") do
      remove :live, :boolean, default: false, null: false
    end

    alter table("partners") do
      add :approval_status, :string, null: false, default: "pending"
    end

    flush()

    execute "UPDATE partners SET approval_status = 'approved' WHERE live = 't'", ""

    alter table("partners") do
      remove :live, :boolean, default: false, null: false
    end
  end
end
