defmodule OmegaBraveraWeb.Api.Mutation.UpdateEmailPasswordTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Fixtures}

  @change_user_email """
  mutation($newEmail: String!) {
    changeUserEmail(newEmail: $newEmail) {
      id
      email
    }
  }
  """

  @confirm_update_email """
  mutation($newEmailVerificationCode: String!) {
    confirmUpdateEmail(newEmailVerificationCode: $newEmailVerificationCode) {
      id
      email
    }
  }
  """

  @update_password """
  mutation($oldPassword: String!, $newPassword: String!, $newPasswordConfirm: String!) {
    updatePassword(oldPassword: $oldPassword, newPassword: $newPassword, newPasswordConfirm: $newPasswordConfirm) {
      id
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

  test "can change user email", %{conn: conn, user: %{id: user_id, email: email}} do
    new_email = "new@email.com"

    response =
      post(conn, "/api", %{query: @change_user_email, variables: %{"newEmail" => new_email}})

    assert %{"data" => %{"changeUserEmail" => %{"email" => ^email}}} =
             json_response(response, 200)

    user = Accounts.get_user!(user_id)
    assert ^new_email = user.new_email
    assert false == is_nil(user.new_email_verification_code)

    response =
      post(conn, "/api", %{
        query: @confirm_update_email,
        variables: %{"newEmailVerificationCode" => user.new_email_verification_code}
      })

    assert %{"data" => %{"confirmUpdateEmail" => %{"email" => ^new_email}}} =
             json_response(response, 200)
  end

  test "return error if email is invalid or code is incorrect", %{conn: conn, user: user} do
    response = post(conn, "/api", %{query: @change_user_email, variables: %{"newEmail" => "123"}})

    assert %{"errors" => [%{"details" => %{"new_email" => ["is not a valid email"]}}]} =
             json_response(response, 200)

    {:ok, _user} = Accounts.update_user_email(user, %{new_email: "c@email.com"})

    response =
      post(conn, "/api", %{
        query: @confirm_update_email,
        variables: %{"newEmailVerificationCode" => "123456"}
      })

    assert %{
             "errors" => [
               %{
                 "details" => %{
                   "new_email_verification_code" => ["The verification code is incorrect."]
                 }
               }
             ]
           } = json_response(response, 200)
  end

  test "can change user password", %{conn: conn, user: %{id: user_id}} do
    response =
      post(conn, "/api", %{
        query: @update_password,
        variables: %{
          "oldPassword" => "Testies@123",
          "newPassword" => "Dev@1234",
          "newPasswordConfirm" => "Dev@1234"
        }
      })

    user_id_string = to_string(user_id)

    assert %{"data" => %{"updatePassword" => %{"id" => ^user_id_string}}} =
             json_response(response, 200)
  end

  test "return error if old password is incorrect or new password doesn't match", %{conn: conn} do
    response =
      post(conn, "/api", %{
        query: @update_password,
        variables: %{
          "oldPassword" => "password",
          "newPassword" => "Dev@1234",
          "newPasswordConfirm" => "Dev@1234"
        }
      })

    assert %{"errors" => [%{"message" => "The old password is incorrect."}]} =
             json_response(response, 200)

    response =
      post(conn, "/api", %{
        query: @update_password,
        variables: %{
          "oldPassword" => "Testies@123",
          "newPassword" => "Dev41234",
          "newPasswordConfirm" => "Dev41234"
        }
      })

    assert %{
             "errors" => [
               %{
                 "message" => "Could not change password",
                 "details" => %{
                   "credential" => %{
                     "password" => [
                       "Not enough special characters (only 0 instead of at least 1)"
                     ]
                   }
                 }
               }
             ]
           } = json_response(response, 200)
  end
end
