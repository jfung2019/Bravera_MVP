defmodule OmegaBraveraWeb.Api.Mutation.NotificationDeviceTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.{Accounts, Fixtures}
  import OmegaBravera.Factory

  @register_mutation """
  mutation($token: ID!) {
    registerNotificationToken(token: $token) {
      token
    }
  }
  """

  @enable_push_notifications_mutation """
  mutation($enable: Boolean!) {
    enablePushNotifications(enable: $enable) {
      email
      pushNotifications
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user)
    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"), user: user}
  end

  test "can register device for push notifications", %{conn: conn} do
    token = "123"
    response = post(conn, "/api", %{query: @register_mutation, variables: %{"token" => token}})

    assert %{"data" => %{"registerNotificationToken" => %{"token" => ^token}}} =
             json_response(response, 200)
  end

  test "can enable push notifications from server", %{
    conn: conn,
    user: %{email: email, push_notifications: false, id: user_id}
  } do
    response =
      post(conn, "/api", %{
        query: @enable_push_notifications_mutation,
        variables: %{"enable" => true}
      })

    assert %{
             "data" => %{
               "enablePushNotifications" => %{"pushNotifications" => true, "email" => ^email}
             }
           } = json_response(response, 200)

    assert %{push_notifications: true} = Accounts.get_user!(user_id)
  end
end
