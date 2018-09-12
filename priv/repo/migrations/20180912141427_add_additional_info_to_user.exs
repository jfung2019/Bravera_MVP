defmodule OmegaBravera.Repo.Migrations.AddAdditionalInfoToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :additional_info, :map
    end
  end
end
