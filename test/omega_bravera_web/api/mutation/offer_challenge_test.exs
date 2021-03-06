defmodule OmegaBraveraWeb.Api.Mutation.OfferChallengeTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @query """
  mutation ($offer_challenge: OfferChallengeCreateInput!) {
    createOfferChallenge(input: $offer_challenge){
      offerChallenge{
        id
        slug
        hasTeam
      }
    }
  }
  """

  def credential_fixture() do
    user = insert(:user, %{email: @email})
    Fixtures.credential_fixture(user.id)
  end

  test "create/3 requires a user login to create offer challenge" do
    conn = build_conn()
    offer = insert(:offer)

    conn =
      post(conn, "/api", %{
        query: @query,
        variables: %{"offer_challenge" => %{"offerSlug" => offer.slug}}
      })

    assert %{
             "data" => %{"createOfferChallenge" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => _, "line" => _}],
                 "message" => "not_authorized",
                 "path" => ["createOfferChallenge"]
               }
             ]
           } = json_response(conn, 200)
  end

  test "create/3 requires correct params to create offer challenge" do
    credential = credential_fixture()
    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    conn = build_conn() |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)

    response =
      post(conn, "/api", %{
        query: @query,
        variables: %{"offer_challenge" => %{"offerSlug" => "kfc"}}
      })

    assert response.resp_body =~ "Offer not found"
  end

  test "create/3 creates offer challenges if correct params are given" do
    credential = credential_fixture()
    offer = insert(:offer)
    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    conn = build_conn() |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)

    response =
      post(conn, "/api", %{
        query: @query,
        variables: %{"offer_challenge" => %{"offerSlug" => offer.slug}}
      })

    assert response.resp_body =~ "\"hasTeam\":false"
  end
end
