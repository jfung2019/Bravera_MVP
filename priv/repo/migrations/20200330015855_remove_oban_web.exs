defmodule OmegaBravera.Repo.Migrations.RemoveObanWeb do
  use Ecto.Migration

  defdelegate up, to: ObanWeb.Migrations, as: :down
  defdelegate down, to: ObanWeb.Migrations, as: :up
end
