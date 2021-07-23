defmodule OmegaBraveraWeb.Api.Query.OfferChallengeTest do
  use OmegaBraveraWeb.ConnCase, async: false

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @query """
  query {
    expiredChallenges {
      id
      slug
      hasTeam
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: @email})
    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "create/3 requires a user login to create offer challenge", %{conn: conn} do
    response = post(conn, "/api", %{query: @query})
    assert %{"data" => %{"expiredChallenges" => []}} = json_response(response, 200)
  end
end
