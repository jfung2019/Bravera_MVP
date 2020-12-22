defmodule OmegaBravera.Repo.Migrations.AddUsernameToPartnerUsers do
  use Ecto.Migration

  def up do
    rename table(:partner_user), to: table(:partner_users)

    flush()

    alter table(:partner_users) do
      add :username, :citext, default: nil
    end

    flush()

    execute "UPDATE partner_users SET username = email"

    flush()

    alter table(:partner_users) do
      modify :username, :citext, null: false, default: nil
    end

    create unique_index(:partner_users, [:username])
  end

  def down do
    drop unique_index(:partner_users, [:username])

    alter table(:partner_users) do
      remove :username, :citext
    end

    rename table(:partner_users), to: table(:partner_user)
  end
end
