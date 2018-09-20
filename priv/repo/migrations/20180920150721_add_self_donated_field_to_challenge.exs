defmodule OmegaBravera.Repo.Migrations.AddSelfDonatedFieldToChallenge do
  use Ecto.Migration

  def change do
    alter table("ngo_chals") do
      add :self_donated, :boolean, default: false
    end
  end
end
