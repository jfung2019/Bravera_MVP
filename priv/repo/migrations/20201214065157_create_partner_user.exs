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

    alter table(:offer_vendors) do
      add :partner_user_id, references(:partner_user, on_delete: :delete_all, type: :binary_id), null: true
    end
  end
end
