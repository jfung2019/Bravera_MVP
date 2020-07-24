defmodule OmegaBravera.Repo.Migrations.AddPartnerPassword do
  use Ecto.Migration

  def change do
    alter table(:partners) do
      add :join_password, :string
    end
  end
end
