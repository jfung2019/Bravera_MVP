defmodule OmegaBravera.Repo.Migrations.CreatePartner do
  use Ecto.Migration

  def change do
    create table(:partners) do
      add(:name, :string, null: false)
      add(:introduction, :string)
      add(:opening_times, :text)
      add(:images, {:array, :string}, null: false, default: [])

      timestamps()
    end
  end
end
