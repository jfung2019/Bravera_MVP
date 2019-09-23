defmodule OmegaBravera.Repo.Migrations.AddNgoMinimumImmediateDonation do
  use Ecto.Migration

  def up do
    alter table("ngos") do
      add(:minimum_immediate_donation, :integer)
    end
  end

  def down do
    alter table("ngos") do
      add(:minimum_immediate_donation, :integer)
    end
  end
end
