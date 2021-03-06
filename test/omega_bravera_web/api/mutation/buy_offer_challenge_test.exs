defmodule OmegaBraveraWeb.Api.Mutation.BuyOfferChallengeTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @query """
  mutation($offerSlug: String!){
    buyOfferChallenge(offerSlug: $offerSlug){
      offerChallenge{
        id
      }
    }
  }
  """

  def credential_fixture() do
    user = insert(:user, %{email: @email})

    insert(:device, %{
      uuid: Enum.random(10_000_000..20_000_000) |> Integer.to_string(),
      active: true,
      user_id: user.id
    })

    Fixtures.credential_fixture(user.id)
  end

  test "buy/3 will not allow reward purchase without sufficiant points in user's balance" do
    credential = credential_fixture()
    insert(:point, %{value: Decimal.new(150), user_id: credential.user_id, source: :admin})
    offer = insert(:offer, %{target: 16})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    conn = build_conn() |> put_req_header("authorization", "Bearer #{auth_token}")

    response = post(conn, "/api", %{query: @query, variables: %{"offerSlug" => offer.slug}})

    assert %{
             "errors" => [
               %{
                 "details" => %{"id" => ["Insufficient points"]}
               }
             ]
           } = json_response(response, 200)
  end

  test "buy/3 can create complete challenge, send reward to use, and deduct points from total balance" do
    credential = credential_fixture()
    insert(:point, %{value: Decimal.new(150), user_id: credential.user_id, source: :admin})
    offer = insert(:offer, %{target: 15})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    conn = build_conn() |> put_req_header("authorization", "Bearer #{auth_token}")

    response = post(conn, "/api", %{query: @query, variables: %{"offerSlug" => offer.slug}})

    assert %{
             "data" => %{
               "buyOfferChallenge" => %{"offerChallenge" => %{"id" => _id}}
             }
           } = json_response(response, 200)
  end

  test "buy/3 will stop user from buying offer challenge if offer is linked to group and user is not a member of that group" do
    credential = credential_fixture()
    insert(:point, %{value: Decimal.new(150), user_id: credential.user_id, source: :admin})
    partner = Fixtures.partner_fixture()
    offer = insert(:offer, %{target: 15})
    OmegaBravera.Groups.create_offer_partner(%{partner_id: partner.id, offer_id: offer.id})
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    conn = build_conn() |> put_req_header("authorization", "Bearer #{auth_token}")

    response = post(conn, "/api", %{query: @query, variables: %{"offerSlug" => offer.slug}})

    assert %{"errors" => [%{"message" => "Please join partner to join challenge"}]} =
             json_response(response, 200)
  end
end
