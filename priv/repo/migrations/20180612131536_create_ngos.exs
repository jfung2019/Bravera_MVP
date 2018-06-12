defmodule OmegaBravera.Repo.Migrations.CreateNgos do
  use Ecto.Migration

  def change do
    create table(:ngos) do
      add :user_id, references(:user, on_delete: :nothing)
      add :name, :string
      add :desc, :string
      add :logo, :string
      add :stripe_id, :string
      add :slug, :string

      timestamps(type: :timestamptz)
    end

    create unique_index(:charities, [:slug])
  end
end
