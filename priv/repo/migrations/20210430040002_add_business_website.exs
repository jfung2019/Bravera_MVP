defmodule OmegaBravera.Repo.Migrations.AddBusinessWebsite do
  use Ecto.Migration

  import Ecto.Query

  alias OmegaBravera.Repo

  def change do
    alter table("organizations") do
      add :business_website, :varchar
    end
  end
end
