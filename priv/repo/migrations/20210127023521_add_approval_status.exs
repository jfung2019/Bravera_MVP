defmodule OmegaBravera.Repo.Migrations.AddApprovalStatus do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add :approval_status, :string, null: false, default: "pending"
    end

    flush()

    execute "UPDATE offers SET approval_status = 'approved' WHERE live = 't'", ""
  end
end
