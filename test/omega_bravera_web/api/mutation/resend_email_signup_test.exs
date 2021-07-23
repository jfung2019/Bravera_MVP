defmodule OmegaBraveraWeb.Api.Mutation.ResendEmailSignupTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Fixtures

  @email "sheriefalaa.w@gmail.com"

  @mutation """
  mutation {
    resendWelcomeEmail {
      firstname
      lastname
    }
  }
  """
  def credential_fixture() do
    user = insert(:user, %{email: @email, email_activation_token: "test123"})
    Fixtures.credential_fixture(user.id)
  end

  test "resend welcome email", %{conn: conn} do
    %{user: %{firstname: first_name, lastname: last_name} = user} = credential_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(user)

    response =
      conn
      |> put_req_header("authorization", "Bearer #{auth_token}")
      |> post("/api", %{query: @mutation})

    assert %{
             "data" => %{
               "resendWelcomeEmail" => %{
                 "firstname" => ^first_name,
                 "lastname" => ^last_name
               }
             }
           } = json_response(response, 200)
  end
end
