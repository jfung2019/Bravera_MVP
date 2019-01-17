defmodule OmegaBravera.Repo.Migrations.AddUserEmailVerifiedFields do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Accounts.User}

  def up do
    alter table(:users) do
      add :email_verified, :boolean, default: false
      add :email_activation_token, :string
    end

    flush()

    from(u in User, where: not is_nil(u.email))
    |> Repo.update_all(set: [email_verified: true])
  end

  def down do
    alter table(:users) do
      remove :email_verified
      remove :email_activation_token
    end
  end

end
