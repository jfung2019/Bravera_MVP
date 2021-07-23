defmodule OmegaBraveraWeb.Api.Query.OfferRedeemTest do
  use OmegaBraveraWeb.ConnCase, async: false

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @query """
  query {
    expiredRedeems {
      insertedAt
      offer {
        name
      }
      offerChallenge {
        id
      }
      status
      token
      updatedAt
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: @email})
    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "can get expired redeems", %{conn: conn} do
    response = post(conn, "/api", %{query: @query})
    assert %{"data" => %{"expiredRedeems" => []}} = json_response(response, 200)
  end
end
