defmodule OmegaBraveraWeb.Api.Mutation.EarnOfferChallengeTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  import OmegaBravera.Factory

  @email "sheriefalaa.w@gmail.com"
  @query """
  mutation($offerSlug: String!){
    earnOfferChallenge(offerSlug: $offerSlug){
      offerChallenge{
        id
      }
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: @email})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(user)
    {:ok, user: user, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "earn/3 can create challenge",
       %{conn: conn, user: user} do
    offer = insert(:offer, %{target: 15})

    insert(:device, %{
      uuid: Enum.random(10_000_000..20_000_000) |> Integer.to_string(),
      active: true,
      user_id: user.id
    })

    response = post(conn, "/api", %{query: @query, variables: %{"offerSlug" => offer.slug}})

    assert %{
             "data" => %{
               "earnOfferChallenge" => %{"offerChallenge" => %{"id" => _id}}
             }
           } = json_response(response, 200)
  end

  test "can't earn offer if user does not have a device linked",
       %{conn: conn} do
    offer = insert(:offer, %{target: 15})

    response = post(conn, "/api", %{query: @query, variables: %{"offerSlug" => offer.slug}})

    assert %{
             "data" => %{
               "earnOfferChallenge" => nil
             },
             "errors" => [%{"message" => "Please connect Google Fit / Apple Health to bravera"}]
           } = json_response(response, 200)
  end

  describe "offer with partner" do
    setup %{user: user} do
      insert(:device, %{
        uuid: Enum.random(10_000_000..20_000_000) |> Integer.to_string(),
        active: true,
        user_id: user.id
      })

      partner = Fixtures.partner_fixture()
      offer = insert(:offer, %{target: 15})
      OmegaBravera.Partners.create_offer_partner(%{partner_id: partner.id, offer_id: offer.id})
      {:ok, offer: offer}
    end

    test "cannot earn offer without being in that offer's partner's member", %{
      conn: conn,
      offer: %{slug: slug}
    } do
      response = post(conn, "/api", %{query: @query, variables: %{"offerSlug" => slug}})

      assert %{
               "data" => %{
                 "earnOfferChallenge" => nil
               },
               "errors" => [%{"message" => "Please join partner to join challenge"}]
             } = json_response(response, 200)
    end
  end
end
