defmodule OmegaBraveraWeb.Api.Mutation.UserEmailPermissionText do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Locations, Fixtures}

  @update_email_permission """
  mutation($email_permissions: List!) {
    updateEmailPermission(email_permissions: $email_permissions) {
      emailPermissions
    }
  }
  """

  setup %{conn: conn} do
    {:ok, %{id: location_id}} =
      Locations.create_location(%{name_en: "location1", name_zh: "location1"})

    {:ok, user} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "1",
        email: "user1@email.com",
        email_verified: true,
        location_id: location_id
      })

    credential = Fixtures.credential_fixture(user.id)

    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"), user: user}
  end

  test "can update email permission", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        query: @update_email_permission,
        variables: %{"email_permissions" => ["news", "activity"]}
      })

    assert %{
             "data" => %{"updateEmailPermission" => %{"emailPermissions" => ["news", "activity"]}}
           } = json_response(conn, 200)
  end

  test "return error if input is invalid", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        query: @update_email_permission,
        variables: %{"email_permissions" => ["news", "activities"]}
      })

    assert %{"errors" => [%{"details" => %{"email_permissions" => ["has an invalid entry"]}}]} =
             json_response(conn, 200)
  end
end
