defmodule OmegaBravera.Repo.Migrations.CreatePartnerUser do
  use Ecto.Migration

  def change do
    create table(:partner_user, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :password_hash, :text, null: false
      add :business_type, :text, null: false

      timestamps()
    end

    create unique_index(:partner_user, [:email])
  end
end
