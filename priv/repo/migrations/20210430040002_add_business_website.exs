defmodule OmegaBravera.Repo.Migrations.AddBusinessWebsite do
  use Ecto.Migration

  def change do
    alter table("organizations") do
      add :business_website, :varchar
    end
  end
end
