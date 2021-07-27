defmodule OmegaBravera.Repo.Migrations.AddNewEmail do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :new_email, :citext
      add :new_email_verification_code, :string
    end
  end
end
