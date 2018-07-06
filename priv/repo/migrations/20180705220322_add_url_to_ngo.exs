defmodule OmegaBravera.Repo.Migrations.AddUrlToNgo do
  use Ecto.Migration

  def change do
    alter table(:ngos) do
      add :url, :string
      add :full_desc, :text
    end
  end
end
