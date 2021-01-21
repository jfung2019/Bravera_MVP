defmodule OmegaBravera.Repo.Migrations.AddOrganizationIdToPoints do
  use Ecto.Migration

  def change do
    alter table("points") do
      add :organization_id, references(:organizations, on_delete: :nilify_all, type: :binary_id)
    end
  end
end
