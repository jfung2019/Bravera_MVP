defmodule OmegaBravera.Repo.Migrations.AddOfferRedeemUniqueIndex do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Offers.OfferRedeem}

  def up do
    dups = from(x in OfferRedeem, join: y in OfferRedeem, on: y.user_id == x.user_id and y.offer_challenge_id == x.offer_challenge_id and y.token != x.token and y.id < x.id, distinct: x.token, select: x.id) |> Repo.all()

    from(redeem in OfferRedeem, where: redeem.id in ^dups) |> Repo.delete_all()

    create(unique_index(:offer_redeems, [:offer_challenge_id, :user_id]))
  end

  def down do
    drop(unique_index(:offer_redeems, [:offer_challenge_id, :user_id]))
  end
end
