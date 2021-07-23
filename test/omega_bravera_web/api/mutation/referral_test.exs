defmodule OmegaBraveraWeb.Api.Mutation.ReferralTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

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
    Fixtures.credential_fixture(user.id)
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
