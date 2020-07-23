defmodule OmegaBraveraWeb.Api.Mutation.PartnerTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  import OmegaBravera.Factory

  @vote_partner_mutation """
  mutation($partnerId: ID!) {
    votePartner(partnerId: $partnerId) {
      user {
        profilePicture
      }
    }
  }
  """

  @join_partner_mutation """
  mutation($partnerId: ID!) {
    joinPartner(partnerId: $partnerId) {
      id
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
    response = post(conn, "/api", %{query: @vote_partner_mutation, variables: %{"partnerId" => partner_id}})
    assert %{"data" => %{"votePartner" => [_location]}} = json_response(response, 200)
  end

  test "can join partner", %{conn: conn, partner: %{id: partner_id}} do
    response = post(conn, "/api", %{query: @join_partner_mutation, variables: %{"partnerId" => partner_id}})
    string_partner_id = to_string(partner_id)
    assert %{"data" => %{"joinPartner" => %{"id" => ^string_partner_id}}} = json_response(response, 200)
  end
end
