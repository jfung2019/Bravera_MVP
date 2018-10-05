defmodule OmegaBravera.Repo.Migrations.AddNgoCurrency do
  use Ecto.Migration

  def change do
    alter table("ngos") do
      add :currency, :string, null: false, default: "Hong Kong Dollar (HKD)"
    end
  end
end
