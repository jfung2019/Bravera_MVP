defmodule OmegaBravera.Repo.Migrations.RemoveRandomUsername do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :username, :citext, null: false, default: nil
    end

    drop unique_index(:users, [:username])
  end

  def down do
    alter table(:users) do
      modify :username, :citext,
        null: false,
        default: fragment("substring(md5(random()::text) from 1 for 8)")
    end

    create unique_index(:users, [:username])
  end
end
