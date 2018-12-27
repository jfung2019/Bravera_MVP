defmodule OmegaBravera.Repo.Migrations.ChangeFullDescDescToText do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      modify :desc, :text
      modify :full_desc, :text
    end
  end
end
