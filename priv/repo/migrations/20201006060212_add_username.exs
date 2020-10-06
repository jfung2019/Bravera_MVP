defmodule OmegaBravera.Repo.Migrations.AddUsername do
  use Ecto.Migration

  import Ecto.Query

  alias OmegaBravera.{Repo, Accounts.User}

  def up do
    alter table(:users) do
      add :username, :string, null: false, default: "set name"
    end

    flush()

    from(u in User,
      where: u.username == "set name",
      update: [set: [username: fragment("? || ? || ?", u.firstname, " ", u.lastname)]]
    )
    |> Repo.update_all([])
  end

  def down do
    alter table(:users) do
      remove :username
    end
  end
end
