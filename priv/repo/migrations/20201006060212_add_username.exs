defmodule OmegaBravera.Repo.Migrations.AddUsername do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION citext", "DROP EXTENSION citext"

    alter table(:users) do
      add :username, :citext,
        null: false,
        default: fragment("substring(md5(random()::text) from 1 for 8)")
    end

    create unique_index(:users, [:username])
  end
end
