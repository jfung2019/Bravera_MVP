defmodule OmegaBravera.Repo.Migrations.AddEmailRestrictionToGroup do
  use Ecto.Migration

  def change do
    alter table("partners") do
      add :email_restriction, :citext
    end
  end
end
