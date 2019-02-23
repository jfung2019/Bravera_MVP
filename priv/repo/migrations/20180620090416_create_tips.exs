defmodule OmegaBravera.Repo.Migrations.CreateTips do
  use Ecto.Migration

  def change do
    create table(:tips) do
      add(:amount, :integer)
      add(:currency, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:tips, [:user_id]))
  end
end
