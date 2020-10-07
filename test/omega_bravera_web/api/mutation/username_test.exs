defmodule OmegaBraveraWeb.Api.Mutation.UsernaneTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Locations, Fixtures}

  @set_username """
  mutation($username: String!) {
    setUsername(username: $username) {
      username
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

  test "can set username after signup", %{conn: conn} do
    conn = post(conn, "/api", %{query: @set_username, variables: %{"username" => "new username"}})

    assert %{"data" => %{"setUsername" => %{"username" => "new username"}}} =
             json_response(conn, 200)
  end

  test "can update username", %{conn: conn, user: user} do
    {:ok, %{username: "name1"} = user} = Accounts.update_user(user, %{username: "name1"})

    {:ok, %{username: "name1"}} = Accounts.update_user(user, %{firstname: "first"})

    conn = post(conn, "/api", %{query: @set_username, variables: %{"username" => "new username"}})

    assert %{"data" => %{"setUsername" => %{"username" => "new username"}}} =
             json_response(conn, 200)
  end
end
