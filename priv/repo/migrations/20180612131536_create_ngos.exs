defmodule OmegaBravera.Repo.Migrations.CreateNgos do
  use Ecto.Migration

  def change do
    create table(:ngos) do
      add :user_id, references(:users, on_delete: :nothing)
      add :name, :string
      add :desc, :string
      add :logo, :string
      add :image, :string
      add :stripe_id, :string
      add :slug, :string

      timestamps(type: :timestamptz)
    end

    create unique_index(:ngos, [:slug])
  end
end
