defmodule OmegaBravera.Repo.Migrations.AddImagesToOffer do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add(:images, {:array, :string}, null: false, default: [])
    end
  end
end
