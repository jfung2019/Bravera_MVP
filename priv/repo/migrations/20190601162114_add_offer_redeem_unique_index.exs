defmodule OmegaBravera.Repo.Migrations.AddOfferRedeemUniqueIndex do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo, Offers.OfferRedeem}

  def up do
    dups =
      from(o in OfferRedeem,
        group_by: [:offer_challenge_id, :user_id],
        select: min(o.id)
      )
      |> Repo.all()

    from(redeem in OfferRedeem, where: redeem.id not in ^dups) |> Repo.delete_all()
    flush()
    create(unique_index(:offer_redeems, [:offer_challenge_id, :user_id]))
  end

  def down do
    drop(unique_index(:offer_redeems, [:offer_challenge_id, :user_id]))
  end
end
