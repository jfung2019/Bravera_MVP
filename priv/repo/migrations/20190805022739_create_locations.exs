defmodule OmegaBravera.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add(:name_en, :string, null: false)
      add(:name_zh, :string, null: false)

      timestamps()
    end

    alter table(:users) do
      add(:location_id, references(:locations))
    end

    alter table(:offers) do
      add(:location_id, references(:locations))
    end

    flush()

    execute(
      "INSERT INTO locations (name_en, name_zh, inserted_at, updated_at) VALUES ('Hong Kong', '香港', now(), now())",
      ""
    )

    execute("UPDATE users SET location_id = (SELECT id FROM locations lIMIT 1)", "")
    execute("UPDATE offers SET location_id = (SELECT id FROM locations lIMIT 1)", "")
  end
end
