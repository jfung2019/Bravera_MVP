defmodule OmegaBraveraWeb.UserProfileView do
  use OmegaBraveraWeb, :view

  alias OmegaBravera.Offers.OfferChallenge

  def get_offer_challenge_link(conn, user_id \\ nil, offer_challenge)

  def get_offer_challenge_link(conn, user_id, %OfferChallenge{
        offer: %{slug: offer_slug},
        slug: slug,
        status: "complete",
        offer_redeems: offer_redeems
      }) do
    redeem = Enum.find(offer_redeems, nil, &(&1.user_id == user_id and &1.status == "redeemed"))

    cond do
      is_nil(redeem) ->
        link("GET REWARD!",
          to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug),
          class: "text-danger"
        )

      true ->
        link("REWARD REDEEMED",
          to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug),
          class: "text-secondary"
        )
    end
  end

  def get_offer_challenge_link(conn, _user_id, %OfferChallenge{
        offer: %{slug: offer_slug},
        slug: slug,
        status: "active"
      }),
      do:
        link("LIVE",
          to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug),
          class: "text-success"
        )

  def get_offer_challenge_link(conn, _user_id, %OfferChallenge{
        offer: %{slug: offer_slug},
        slug: slug,
        status: "expired"
      }),
      do:
        link("EXPIRED",
          to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug),
          class: "text-secondary"
        )

  def get_offer_challenge_link(conn, _user_id, %OfferChallenge{
        offer: %{slug: offer_slug},
        slug: slug,
        status: "pre_registration"
      }),
      do:
        link("Pre Registration",
          to: Routes.offer_offer_challenge_path(conn, :show, offer_slug, slug),
          class: "text-info"
        )
end
