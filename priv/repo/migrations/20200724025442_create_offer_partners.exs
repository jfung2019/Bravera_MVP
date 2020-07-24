defmodule OmegaBravera.Repo.Migrations.CreateOfferPartners do
  use Ecto.Migration

  def change do
    create table(:offer_partners, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :offer_id, references(:offers, on_delete: :delete_all), null: false
      add :partner_id, references(:partners, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:offer_partners, [:offer_id])
    create index(:offer_partners, [:partner_id])
    create unique_index(:offer_partners, [:offer_id, :partner_id])
    flush()

    execute(
      "INSERT INTO offer_partners (id, partner_id, offer_id, inserted_at, updated_at) SELECT uuid_generate_v4(), p.id, o.id, now(), now() FROM offers o LEFT JOIN partners p ON o.partner_id = p.id WHERE p.id IS NOT NULL"
    )

    flush()

    alter table(:offers) do
      remove :partner_id
    end
  end
end
