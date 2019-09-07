defmodule OmegaBraveraWeb.Api.Mutation.SignupTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts}

  @valid_user_input %{
    "firstname" => "Sherief",
    "lastname" => "Who",
    "email" => "sheriefalaa.w@gmail.com",
    "acceptTerms" => true,
    "locationId" => 1,
    "locale" => "en",
    "credential" => %{
      "password" => "dev123",
      "passwordConfirm" => "dev123"
    }
  }

  @invalid_user_input %{
    "firstname" => "Sherief",
    "lastname" => "Who",
    "email" => "bad email",
    "acceptTerms" => true,
    "locationId" => 1,
    "locale" => "zh",
    "credential" => %{
      "password" => "dev123",
      "passwordConfirm" => "bad confirm"
    }
  }

  @query """
  mutation createUser($user: UserSignupInput!) {
    createUser(input: $user) {
      token
      user {
        id
        firstname
        lastname
        email
      }
    }
  }
  """

  test "create_user/3 creates a user when valid input provided" do
    response =
      post(build_conn(), "/api", %{query: @query, variables: %{"user" => @valid_user_input}})

    email = @valid_user_input["email"]

    assert %{"data" => %{"createUser" => %{"user" => %{"email" => ^email}}}} =
             json_response(response, 200)

    assert %{email: ^email} = Accounts.list_users() |> hd()
  end

  test "create_user/3 returns errors if data is invalid" do
    response =
      post(build_conn(), "/api", %{query: @query, variables: %{"user" => @invalid_user_input}})

    assert %{"errors" => [%{"details" => %{"email" => ["has invalid format"]}}]} =
             json_response(response, 200)
  end

  test "create_user/3 returns errors locale is invalid" do
    response =
      post(build_conn(), "/api", %{
        query: @query,
        variables: %{"user" => %{@invalid_user_input | "locale" => "xxx"}}
      })

    assert %{
             "errors" => [
               %{"message" => "Locale is required to signup. Supported locales are: en, zh."}
             ]
           } = json_response(response, 200)
  end
end
