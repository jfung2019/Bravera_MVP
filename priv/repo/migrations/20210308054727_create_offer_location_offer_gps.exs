defmodule OmegaBravera.Repo.Migrations.CreateOfferLocationOfferGps do
  use Ecto.Migration

  import Ecto.Query

  alias OmegaBravera.{Repo, Offers.Offer, Offers.OfferLocation}

  def change do
    create table("offer_locations", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :offer_id, references(:offers, on_delete: :delete_all), null: false
      add :location_id, references(:locations, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:offer_locations, [:offer_id, :location_id])

    execute "CREATE EXTENSION IF NOT EXISTS postgis", "DROP EXTENSION IF EXISTS postgis"

    create table("offer_gps_coordinates", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :offer_id, references(:offers, on_delete: :delete_all), null: false
      add :address, :string, null: false
      add :geom, :geography, null: false

      timestamps()
    end

    flush()

    now = Timex.now() |> NaiveDateTime.truncate(:second)

    offer_locations =
      from(o in "offers", where: not is_nil(o."location_id"), select: %{id: o."id", location_id: o."location_id"})
      |> Repo.all()
      |> Enum.map(
        &%{
          offer_id: &1.id,
          location_id: &1.location_id,
          inserted_at: now,
          updated_at: now
        }
      )

    Repo.insert_all(OfferLocation, offer_locations)

    alter table("offers") do
      remove :location_id
    end
  end
end
