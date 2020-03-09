defmodule OmegaBravera.Repo.Migrations.CreatePartnerLocations do
  use Ecto.Migration

  def change do
    create table(:partner_locations) do
      add(:address, :string, null: false)
      add(:latitude, :decimal, null: false)
      add(:longitude, :decimal, null: false)
      add(:partner_id, references(:partners, on_delete: :delete_all), null: false)

      timestamps()
    end
  end
end
