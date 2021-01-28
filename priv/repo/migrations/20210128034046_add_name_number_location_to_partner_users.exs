defmodule OmegaBravera.Repo.Migrations.AddNameNumberLocationToPartnerUsers do
  use Ecto.Migration

  def change do
    alter table(:partner_users) do
      add :first_name, :varchar
      add :last_name, :varchar
      add :location_id, references("locations")
      add :contact_number, :varchar
    end

    flush()

    execute "UPDATE partner_users SET first_name = 'First Name', last_name = 'Last Name', location_id = 1, contact_number = '00000000'",
            ""

    drop constraint(:partner_users, :partner_users_location_id_fkey)

    alter table(:partner_users) do
      modify :first_name, :varchar, null: false
      modify :last_name, :varchar, null: false
      modify :location_id, references("locations"), null: false
      modify :contact_number, :varchar, null: false
    end
  end
end
