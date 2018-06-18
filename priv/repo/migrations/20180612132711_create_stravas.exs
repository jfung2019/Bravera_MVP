defmodule OmegaBravera.Repo.Migrations.CreateStravas do
  use Ecto.Migration

  def change do
    create table(:stravas) do
      add :email, :string
      add :athlete_id, :integer
      add :firstname, :string
      add :lastname, :string
      add :token, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :timestamptz)
    end

    create index(:stravas, [:user_id])
    create index(:stravas, [:email])
  end
end
