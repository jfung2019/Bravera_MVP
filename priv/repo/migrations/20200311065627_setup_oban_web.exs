defmodule OmegaBravera.Repo.Migrations.SetupObanWeb do
  use Ecto.Migration

  defdelegate up, to: ObanWeb.Migrations
  defdelegate down, to: ObanWeb.Migrations
end
