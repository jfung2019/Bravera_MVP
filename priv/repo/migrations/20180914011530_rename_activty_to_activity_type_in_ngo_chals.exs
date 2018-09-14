defmodule OmegaBravera.Repo.Migrations.RenameActiivtyToActivityTypeInNgoChals do
  use Ecto.Migration

  def change do
    rename table("ngo_chals"), :activity, to: :activity_type
  end
end
