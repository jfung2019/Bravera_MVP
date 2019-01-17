defmodule OmegaBravera.Repo.Migrations.AddUserEmailVerifiedFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email_verified, :boolean, default: nil
      add :email_activation_token, :string, default: nil
    end
  end
end
