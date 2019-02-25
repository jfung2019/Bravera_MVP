defmodule OmegaBravera.Repo.Migrations.CreateStrCustomers do
  use Ecto.Migration

  def change do
    create table(:str_customers) do
      add(:cus_id, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:str_customers, [:user_id]))
    create(unique_index(:str_customers, [:cus_id]))
  end
end
