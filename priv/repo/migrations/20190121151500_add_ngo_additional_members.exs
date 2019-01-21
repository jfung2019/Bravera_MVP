defmodule OmegaBravera.Repo.Migrations.AddNgoAdditionalMembers do
  use Ecto.Migration

  def change do
    alter table("ngos") do
      add :additional_members, :integer, default: 0, null: false
    end
  end
end
