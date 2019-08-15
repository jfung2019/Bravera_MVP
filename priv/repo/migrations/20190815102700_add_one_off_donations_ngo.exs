defmodule OmegaBravera.Repo.Migrations.AddOneOffDonationsNgo do
  use Ecto.Migration

  def up do
    alter table("ngos") do
      add :one_off_donations, :boolean, default: false
    end
  end

  def down do
    remove :one_off_donations
  end
end
