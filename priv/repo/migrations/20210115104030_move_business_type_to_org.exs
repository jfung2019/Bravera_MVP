defmodule OmegaBravera.Repo.Migrations.MoveBusinessTypeToOrg do
  use Ecto.Migration

  alias OmegaBravera.{Accounts.Organization, Repo}

  import Ecto.Query

  def change do
    alter table("organizations") do
      add :business_type, :text
    end

    flush()

    Repo.update_all(from(o in Organization, where: is_nil(o.business_type)),
      set: [business_type: "Service"]
    )

    alter table("partner_users") do
      remove :business_type
    end

    alter table("organizations") do
      modify :business_type, :text, null: false
    end
  end
end
