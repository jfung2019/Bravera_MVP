defmodule OmegaBravera.Repo.Migrations.CreateUserEmailCategories do
  use Ecto.Migration

  def change do
    create table(:user_email_categories) do
      add(:category_id, references(:email_categories, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:user_email_categories, [:category_id]))
    create(index(:user_email_categories, [:user_id]))

    create(unique_index(:user_email_categories, [:category_id, :user_id]))
  end
end
