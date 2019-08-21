defmodule OmegaBravera.Repo.Migrations.TruncatePoints do
  use Ecto.Migration

  def change do
    execute("TRUNCATE points;")
  end
end
