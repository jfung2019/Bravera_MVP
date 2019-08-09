defmodule OmegaBraveraWeb.Api.Mutation.SignupTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts}

  @valid_user_input %{
    "firstname" => "Sherief",
    "lastname" => "Who",
    "email" => "sheriefalaa.w@gmail.com",
    "acceptTerms" => true,
    "locationId" => 1,
    "credential" => %{
      "password" => "dev123",
      "passwordConfirm" => "dev123"
    }
  }

  @query """
  mutation createUser($user: UserSignupInput!) {
    createUser(input: $user) {
      id
      firstname
      lastname
      email
    }
  }
  """

  test "creating a user session" do
    response = post(build_conn(), "/api", %{query: @query, variables: %{"user" => @valid_user_input}})
    email = @valid_user_input["email"]
    assert %{"data" => %{ "createUser" => %{"email" => ^email}}} = json_response(response, 200)
    assert %{email: ^email} = Accounts.list_users() |> hd()
  end
end
