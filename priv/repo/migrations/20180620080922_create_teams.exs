defmodule OmegaBravera.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :activity, :string
      add :name, :string
      add :location, :string
      add :user_id, references(:user, on_delete: :nothing)
      add :ngo_id, references(:ngo, on_delete: :nothing)

      timestamps()
    end

    create index(:teams, [:user_id])
    create index(:teams, [:ngo_id])
  end
end
