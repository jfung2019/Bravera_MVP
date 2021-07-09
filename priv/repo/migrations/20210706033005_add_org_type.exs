defmodule OmegaBravera.Repo.Migrations.AddOrgType do
  use Ecto.Migration

  def change do
    alter table("organizations") do
      add :account_type, :string, null: false, default: "full"
    end
  end
end
