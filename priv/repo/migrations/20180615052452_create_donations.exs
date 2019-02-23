defmodule OmegaBravera.Repo.Migrations.CreateDonations do
  use Ecto.Migration

  def change do
    create table(:donations) do
      add(:amount, :decimal)
      add(:currency, :string)
      add(:str_src, :string)
      add(:milestone, :integer)
      add(:status, :string)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:ngo_chal_id, references(:ngo_chals, on_delete: :nothing))
      add(:ngo_id, references(:ngos, on_delete: :nothing))

      timestamps(type: :timestamptz)
    end

    create(index(:donations, [:user_id]))
    create(index(:donations, [:ngo_chal_id]))
    create(index(:donations, [:ngo_id]))
  end
end
