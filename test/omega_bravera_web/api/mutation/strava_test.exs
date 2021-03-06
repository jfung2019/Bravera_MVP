defmodule OmegaBraveraWeb.Api.Mutation.StravaTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Fixtures, Trackers}

  @switch_user_sync_type """
  mutation($syncType: SyncType!) {
    switchUserSyncType(syncType: $syncType) {
      syncType
      stravaConnected
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

  test "Cannot switch to sync with Strava if not connected", %{conn: conn} do
    response =
      post(conn, "/api", %{query: @switch_user_sync_type, variables: %{"syncType" => "STRAVA"}})

    assert %{"errors" => [%{"message" => "Please connect to Strava before switching"}]} =
             json_response(response, 200)
  end

  test "Can switch to Strava", %{conn: conn, user: %{id: user_id}} do
    Trackers.create_strava(user_id, %{
      firstname: "first",
      lastname: "last",
      athlete_id: 1234,
      token: "abc"
    })

    response =
      post(conn, "/api", %{query: @switch_user_sync_type, variables: %{"syncType" => "STRAVA"}})

    %{
      "data" => %{
        "switchUserSyncType" => %{"stravaConnected" => true, "syncType" => "STRAVA"}
      }
    } = json_response(response, 200)
  end
end
