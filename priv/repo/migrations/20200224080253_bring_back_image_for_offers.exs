defmodule OmegaBravera.Repo.Migrations.BringBackImageForOffers do
  use Ecto.Migration

  def change do
    alter table(:offers) do
      add(:image, :string)
    end

    flush()

    execute("UPDATE offers SET image = images[1], images = images[2:]")
  end
end
