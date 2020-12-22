defmodule OmegaBravera.Repo.Migrations.AddResetPasswordFieldsToPartnerUser do
  use Ecto.Migration

  def change do
    alter table(:partner_users) do
      add :reset_token, :string
      add :reset_token_created, :utc_datetime
    end

    create unique_index(:partner_users, [:reset_token])
  end
end
