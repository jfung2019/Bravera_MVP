defmodule OmegaBravera.Repo.Migrations.AddBusinessWebsite do
  use Ecto.Migration

  import Ecto.Query

  alias OmegaBravera.Repo

  def change do
    alter table("organizations") do
      add :business_website, :citext
    end

    flush()

    from(o in "organizations")
    |> Repo.update_all(set: [business_website: "https://www.bravera.fit/"])

    alter table("organizations") do
      modify :business_website, :citext, null: false
    end
  end
end
