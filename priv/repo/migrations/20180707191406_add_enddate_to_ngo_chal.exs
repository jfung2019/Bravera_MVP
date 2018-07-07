defmodule OmegaBravera.Repo.Migrations.AddEnddateToNgoChal do
  use Ecto.Migration

  def change do
    alter table(:ngo_chals) do
      add :end_date, :utc_datetime
    end
  end
end
