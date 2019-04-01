defmodule OmegaBravera.Repo.Migrations.DonorEmailUnique do
  use Ecto.Migration

  def change do
    create(unique_index("donors", [:email]))
  end
end
