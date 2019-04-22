defmodule OmegaBravera.Repo.Migrations.MoveRedeemTokensToOfferRedeems do
  use Ecto.Migration
  import Ecto.Query

  alias OmegaBravera.{Repo}
  alias OmegaBravera.Offers.{OfferChallenge, OfferRedeem}

  def up do
    alter table("offer_redeems") do
      add(:token, :string)
      add(:status, :string)

      remove(:team_id)
    end

    flush()

    # Active Offer Challenges without redeems
    from(
      oc in OfferChallenge,
      where: oc.status == ^"active" and oc.has_team == false,
      preload: [:user, offer: [:vendor]]
    )
    |> Repo.all()
    |> Enum.map(fn active_offer_challenge ->
      OfferRedeem.create_changeset(
        %OfferRedeem{},
        active_offer_challenge,
        active_offer_challenge.offer.vendor,
        %{}
      )
      |> Repo.insert()
    end)

    completed_solo_offer_challenges =
      from(
        oc in OfferChallenge,
        where: oc.status == ^"complete" and oc.has_team == false,
        preload: [:offer_redeems, :user, offer: [:vendor]]
      )
      |> Repo.all()

    # Solo Offer Challenges that has no redeem yet.
    Enum.map(completed_solo_offer_challenges, fn c ->
      if length(c.offer_redeems) == 0 do
        OfferRedeem.create_changeset(%OfferRedeem{}, c, c.offer.vendor, %{token: c.redeem_token})
        |> Repo.insert()
      end
    end)

    # Solo Offer Challenge that has a redeem.
    Enum.map(completed_solo_offer_challenges, fn c ->
      if length(c.offer_redeems) > 0 do
        c.offer_redeems
        |> hd()
        |> OfferRedeem.update_changeset(%{token: c.redeem_token, status: "redeemed"})
        |> Repo.update!()
      end
    end)
  end

  def down do
    alter table("offer_redeems") do
      remove(:token)
      remove(:status)

      add(:team_id, references("offer_challenge_teams", on_delete: :nothing))
    end
  end
end
