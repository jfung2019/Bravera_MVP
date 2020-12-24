defmodule OmegaBravera.Repo.Migrations.AddPartnerUserToGroup do
  use Ecto.Migration

  def change do
    alter table(:partners) do
      add :partner_user_id, references(:partner_users, type: :binary_id, on_delete: :nilify_all)
    end
  end
end
