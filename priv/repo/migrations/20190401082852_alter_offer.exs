defmodule OmegaBravera.Repo.Migrations.AlterOffer do
  use Ecto.Migration

  def change do
    alter table("offers") do
      modify(:desc, :text)
    end
  end
end
