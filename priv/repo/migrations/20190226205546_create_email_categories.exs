defmodule OmegaBravera.Repo.Migrations.CreateEmailCategories do
  use Ecto.Migration

  def change do
    create table(:email_categories) do
      add :title, :string
      add :description, :string

      timestamps(type: :timestamptz)
    end

  end
end
