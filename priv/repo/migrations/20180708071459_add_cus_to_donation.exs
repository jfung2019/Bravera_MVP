defmodule OmegaBravera.Repo.Migrations.AddCusToDonation do
  use Ecto.Migration

  def change do
    alter table(:donations) do
      add(:str_cus_id, :string)
    end
  end
end
