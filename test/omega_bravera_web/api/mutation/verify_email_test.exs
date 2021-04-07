defmodule OmegaBraveraWeb.Api.Mutation.VerifyEmailTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.Fixtures
  import OmegaBravera.Factory

  @verify_email """
  mutation($code: String!) {
    verifyEmail(code: $code) {
      emailVerified
    }
  }
  """

  @change_email """
  mutation($email: String!) {
    changeEmail(email: $email) {
      id
      email
    }
  }
  """

  setup %{conn: conn} do
    user =
      insert(:user, %{
        email: "test@email.com",
        email_activation_token: "abc",
        email_verified: false
      })

    insert(:user, %{
      email: "test2@email.com",
      email_activation_token: "123",
      email_verified: false
    })

    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok, conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "can verify email", %{conn: conn} do
    response = post(conn, "/api", %{query: @verify_email, variables: %{"code" => "abc"}})

    assert %{"data" => %{"verifyEmail" => %{"emailVerified" => true}}} =
             json_response(response, 200)
  end

  test "can't verify email using other user's code", %{conn: conn} do
    response = post(conn, "/api", %{query: @verify_email, variables: %{"code" => "123"}})

    assert %{
             "errors" => [%{"message" => "The verification code is incorrect. Please try again."}]
           } = json_response(response, 200)
  end

  test "can change email", %{conn: conn} do
    response =
      post(conn, "/api", %{query: @change_email, variables: %{"email" => "change@email.com"}})

    assert %{"data" => %{"changeEmail" => %{"email" => "change@email.com"}}} =
             json_response(response, 200)
  end
end
