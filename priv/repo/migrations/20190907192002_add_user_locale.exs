defmodule OmegaBravera.Repo.Migrations.AddUserLocale do
  use Ecto.Migration

  def up do
    alter table("users") do
      add(:locale, :string, default: "en")
    end
  end

  def down do
    alter table("users") do
      remove(:locale)
    end
  end
end
