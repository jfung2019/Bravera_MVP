defmodule OmegaBraveraWeb.Api.Mutation.DeviceTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation($uuid: String!, $active: Boolean!){
    registerDevice(input: {uuid: $uuid, active: $active}) {
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

  setup %{conn: conn} do
    credential = credential_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    conn = conn |> put_req_header("authorization", "Bearer #{auth_token}")
    {:ok, conn: conn}
  end

  test "register_device/3 can register device and return its token more than once", %{conn: conn} do
    response =
      post(
        conn,
        "/api",
        %{
          query: @query,
          variables: %{
            "uuid" => "aasas1231",
            "active" => true
          }
        }
      )

    assert %{
             "data" => %{
               "registerDevice" => %{
                 "expiresAt" => _expires_at,
                 "token" => token
               }
             }
           } = json_response(response, 200)

    assert {:ok, {:device_uuid, "aasas1231"}} == OmegaBraveraWeb.Api.Auth.decrypt_token(token)

    response =
      post(
        conn,
        "/api",
        %{
          query: @query,
          variables: %{
            "uuid" => "aasas1231",
            "active" => true
          }
        }
      )

    assert %{
             "data" => %{
               "registerDevice" => %{
                 "expiresAt" => _expires_at,
                 "token" => token
               }
             }
           } = json_response(response, 200)

    assert {:ok, {:device_uuid, "aasas1231"}} == OmegaBraveraWeb.Api.Auth.decrypt_token(token)
  end
end
