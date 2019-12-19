defmodule OmegaBraveraWeb.Api.Mutation.ReferralTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Repo, Accounts.Credential}

  @email "sheriefalaa.w@gmail.com"
  @password "strong passowrd"
  @query """
  mutation{
    createReferral{
      referral{
        token
      }
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

  test "create_referral/3 can create referral and return its token" do
    credential = credential_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    conn = build_conn() |> put_req_header("authorization", "Bearer #{auth_token}")

    response = post(conn, "/api", %{query: @query})

    assert %{
             "data" => %{
               "createReferral" => %{
                 "referral" => %{
                   "token" => _token
                 }
               }
             }
           } = json_response(response, 200)
  end
end
