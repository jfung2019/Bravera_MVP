defmodule OmegaBravera.Repo.Migrations.FixNgoSeq do
  use Ecto.Migration

  def up do
    execute("SELECT setval('ngos_id_seq', (SELECT MAX(id) from \"ngos\"));")
  end

  def down do
    execute("SELECT setval('ngos_id_seq', 1);")
  end
end
