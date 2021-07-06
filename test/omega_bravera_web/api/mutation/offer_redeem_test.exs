defmodule OmegaBraveraWeb.Api.Mutation.OfferRedeemTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Offers, Fixtures}

  @claim_online_offer_reward """
  mutation($offerChallengeSlug: String!) {
    claimOnlineOfferReward(offerChallengeSlug: $offerChallengeSlug) {
      status
      offerChallenge {
        slug
      }
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user)
    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    offer =
      insert(:offer, %{
        offer_type: :online,
        open_registration: false,
        pre_registration_start_date: Timex.now(),
        start_date: Timex.shift(Timex.now(), days: 5),
        end_date: Timex.shift(Timex.now(), days: 10),
        time_limit: 0
      })

    {:ok, offer_challenge} = Offers.create_offer_challenge(offer, user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     offer_challenge: offer_challenge}
  end

  test "can set rewards as redeemed", %{
    conn: conn,
    offer_challenge: %{slug: offer_challenge_slug}
  } do
    response =
      post(conn, "/api", %{
        query: @claim_online_offer_reward,
        variables: %{"offerChallengeSlug" => offer_challenge_slug}
      })

    assert %{
             "data" => %{
               "claimOnlineOfferReward" => %{
                 "status" => "redeemed",
                 "offerChallenge" => %{"slug" => ^offer_challenge_slug}
               }
             }
           } = json_response(response, 200)
  end
end
