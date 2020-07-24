defmodule OmegaBravera.Repo.Migrations.AddEmailLinkPhoneToPartners do
  use Ecto.Migration

  def change do
    alter table(:partners) do
      add :email, :string
      add :website, :string
      add :phone, :string
    end
  end
end
