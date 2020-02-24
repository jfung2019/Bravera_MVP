defmodule OmegaBraveraWeb.Api.Query.AccountTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  query {
    userProfile {
      id
      email
      emailVerified
      firstname
      lastname
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
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, token: auth_token, user: credential.user}
  end

  test "user_profile can get all of the users info", %{
    token: token,
    user: %{firstname: first_name, lastname: last_name}
  } do
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @query})

    assert %{
             "data" => %{
               "userProfile" => %{
                 "firstname" => ^first_name,
                 "lastname" => ^last_name
               }
             }
           } = json_response(response, 200)
  end
end
