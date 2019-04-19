defmodule OmegaBravera.Repo.Migrations.AddOfferRedeemTeamId do
  use Ecto.Migration

  def change do
    alter table("offer_redeems") do
      add :team_id, references("offer_challenge_teams", on_delete: :nothing)
    end
  end
end
