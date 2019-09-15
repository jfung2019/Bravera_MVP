defmodule OmegaBraveraWeb.Api.Query.DeviceTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  query {
    refreshDeviceToken{
      token
      expiresAt
    }
  }
  """

  def credential_fixture() do
    user = insert(:user, %{email: @email})

    credential_attrs = %{
      password: @password,
      password_confirmation: @password
    }

    {:ok, credential} =
      Credential.changeset(%Credential{user_id: user.id}, credential_attrs)
      |> Repo.insert()

    credential
    |> Repo.preload(:user)
  end

  setup do
    credential = credential_fixture()
    device = insert(:device, %{user_id: credential.user_id, active: true})
    token = OmegaBraveraWeb.Api.Auth.generate_device_token(device.uuid)
    {:ok, device_token: token, device: device, token: token}
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
end
