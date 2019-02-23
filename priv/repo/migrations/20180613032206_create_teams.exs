defmodule OmegaBravera.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add(:activity, :string)
      add(:name, :string)
      add(:location, :string)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:ngo_id, references(:ngos, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(unique_index(:teams, [:name]))
    create(index(:teams, [:user_id]))
    create(index(:teams, [:ngo_id]))
  end
end
