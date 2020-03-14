defmodule OmegaBraveraWeb.Api.Mutation.PartnerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  import OmegaBravera.Factory

  @mutation """
  mutation($partnerId: ID!) {
    votePartner(partnerId: $partnerId) {
      user {
        profilePicture
      }
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user)
    credential = Fixtures.credential_fixture(user.id)
    partner = Fixtures.partner_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     partner: partner}
  end

  test "can vote for partner to have offers", %{conn: conn, partner: %{id: partner_id}} do
    response = post(conn, "/api", %{query: @mutation, variables: %{"partnerId" => partner_id}})
    assert %{"data" => %{"votePartner" => [_location]}} = json_response(response, 200)
  end
end
