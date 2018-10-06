defmodule OmegaBravera.Repo.Migrations.AddNgoCurrency do
  use Ecto.Migration

  def change do
    alter table("ngos") do
      add :currency, :string, null: false, default: "hkd"
    end
  end
end
