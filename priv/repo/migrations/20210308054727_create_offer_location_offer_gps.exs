defmodule OmegaBravera.Repo.Migrations.CreateOfferLocationOfferGps do
  use Ecto.Migration

  def change do
    create table("offer_locations", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :offer_id, references(:offers, on_delete: :delete_all), null: false
      add :location_id, references(:locations, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:offer_locations, [:offer_id, :location_id])

    create table("offer_gps_coordinates", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :offer_id, references(:offers, on_delete: :delete_all), null: false
      add :address, :string, null: false
      add :latitude, :decimal, null: false
      add :longitude, :decimal, null: false

      timestamps()
    end
  end
end
