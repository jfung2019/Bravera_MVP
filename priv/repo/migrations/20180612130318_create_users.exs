defmodule OmegaBravera.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string)
      add(:firstname, :string)
      add(:lastname, :string)

      timestamps(type: :timestamptz)
    end

    create(unique_index(:users, [:email]))
  end
end
