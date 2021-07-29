defmodule OmegaBravera.Repo.Migrations.AddResetTokenToAdmin do
  use Ecto.Migration

  def change do
    alter table("admin_users") do
      add :reset_token, :string
      add :reset_token_created, :utc_datetime
    end
  end
end
