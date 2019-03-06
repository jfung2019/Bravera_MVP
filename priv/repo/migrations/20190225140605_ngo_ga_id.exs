defmodule OmegaBravera.Repo.Migrations.NgoGaId do
  use Ecto.Migration

  def change do
    alter table("ngos") do
      add(:ga_id, :string, default: nil)
    end
  end
end
