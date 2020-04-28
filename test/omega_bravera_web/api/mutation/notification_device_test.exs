defmodule OmegaBraveraWeb.Api.Mutation.NotificationDeviceTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  import OmegaBravera.Factory

  @mutation """
  mutation($token: ID!) {
    registerNotificationToken(token: $token) {
      token
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user)
    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "can vote for partner to have offers", %{conn: conn} do
    token = "123"
    response = post(conn, "/api", %{query: @mutation, variables: %{"token" => token}})
    assert %{"data" => %{"registerNotificationToken" => %{"token" => ^token}}} = json_response(response, 200)
  end
end
