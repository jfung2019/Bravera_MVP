defmodule OmegaBravera.Repo.Migrations.AddNgoHiddenField do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add(:hidden, :boolean, default: false)
    end
  end
end
