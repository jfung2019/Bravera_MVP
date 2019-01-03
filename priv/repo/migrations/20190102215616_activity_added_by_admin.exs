defmodule OmegaBravera.Repo.Migrations.ActivityAddedByAdmin do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add(:added_by_admin, :boolean, default: false)
    end
  end
end
