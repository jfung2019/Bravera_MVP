defmodule OmegaBravera.Repo.Migrations.RenameOpeningTimesToShortDescription do
  use Ecto.Migration

  def change do
    rename table(:partners), :opening_times, to: :short_description
  end
end
