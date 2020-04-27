defmodule OmegaBravera.Repo.Migrations.AddLivePartnerBoolean do
  use Ecto.Migration

  def change do
    alter table("partners") do
      add :live, :boolean, default: true, null: false
    end
  end
end
