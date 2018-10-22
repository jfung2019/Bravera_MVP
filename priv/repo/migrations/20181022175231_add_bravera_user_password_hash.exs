defmodule OmegaBravera.Repo.Migrations.AddBraveraUserPasswordHash do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :password_hash, :string, null: true
    end
  end
end
