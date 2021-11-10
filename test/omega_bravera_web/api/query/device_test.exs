defmodule OmegaBraveraWeb.Api.Query.DeviceTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @query """
  query {
    refreshDeviceToken{
      token
      expiresAt
    }
  }
  """
  @latest_activity_query """
  query {
    latestDeviceSync {
      lastSyncAt
    }
  }
  """

  setup do
    user = insert(:user, %{email: @email})
    credential = Fixtures.credential_fixture(user.id)
    device = insert(:device, %{user_id: credential.user_id, active: true})
    token = OmegaBraveraWeb.Api.Auth.generate_device_token(device.uuid)
    {:ok, device: device, token: token}
  end

  test "refresh_device_token/3 can refresh device token", %{token: token, device: device} do
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @query})

    assert %{
             "data" => %{
               "refreshDeviceToken" => %{
                 "expiresAt" => _expires_at,
                 "token" => token
               }
             }
           } = json_response(response, 200)

    assert {:ok, {:device_uuid, device.uuid}} == OmegaBraveraWeb.Api.Auth.decrypt_token(token)
  end

  test "latest activity will give inserted_at date of device if no activities have been uploaded",
       %{
         token: token,
         device: device
       } do
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @latest_activity_query})

    assert %{
             "data" => %{
               "latestDeviceSync" => %{"lastSyncAt" => datetime}
             }
           } = json_response(response, 200)

    assert DateTime.to_iso8601(device.inserted_at) == datetime
  end

  test "latest activity will give latest activity inserted_at if there is activities", %{
    token: token,
    device: device
  } do
    now = DateTime.utc_now()
    end_date = DateTime.add(now, 3600, :second)

    assert {:ok, activity} =
             OmegaBravera.Activity.Activities.create_app_activity(
               %{
                 distance: 1.0,
                 start_date: now,
                 end_date: end_date,
                 source: "test",
                 type: "Walk"
               },
               device.user_id,
               device.id
             )

    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @latest_activity_query})

    assert %{
             "data" => %{
               "latestDeviceSync" => %{"lastSyncAt" => datetime}
             }
           } = json_response(response, 200)

    refute DateTime.to_iso8601(device.inserted_at) == datetime
    assert DateTime.to_iso8601(activity.end_date) == datetime
  end
end
