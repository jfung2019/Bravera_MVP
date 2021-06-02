defmodule OmegaBravera.Repo.Migrations.AddBlockedOnToOrganizations do
  use Ecto.Migration

  def change do
    alter table("organizations") do
      add :blocked_on, :utc_datetime
    end
  end
end
