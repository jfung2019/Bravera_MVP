defmodule OmegaBravera.Repo.Migrations.AddTakeChallengeBooleanToOffers do
  use Ecto.Migration

  def change do
    alter table("offers") do
      add :take_challenge, :boolean, default: true, null: false
    end
  end
end
