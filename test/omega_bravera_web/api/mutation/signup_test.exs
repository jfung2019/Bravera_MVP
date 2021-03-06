defmodule OmegaBraveraWeb.Api.Mutation.SignupTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{Accounts, Repo}

  @valid_user_input %{
    "firstname" => "Sherief",
    "lastname" => "Who",
    "email" => "sheriefalaa.w@gmail.com",
    "acceptTerms" => true,
    "locationId" => 1,
    "locale" => "en",
    "setting" => %{
      "dateOfBirth" => "1999-05-05 00:00:00",
      "gender" => "robot"
    },
    "credential" => %{
      "password" => "Dev@1234",
      "passwordConfirm" => "Dev@1234"
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
    },
    "setting" => %{
      "dateOfBirth" => "1999-05-05 00:00:00",
      "gender" => ""
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

    assert %{"errors" => [%{"details" => %{"email" => ["is not a valid email"]}}]} =
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

  test "create_user/3 creates a user and adds points to both users if one referred the other" do
    inviter = insert(:user)
    {:ok, referral} = OmegaBravera.Referrals.get_or_create_referral(inviter.id)

    response =
      post(build_conn(), "/api", %{
        query: @query,
        variables: %{"user" => Map.put_new(@valid_user_input, "referral_token", referral.token)}
      })

    email = @valid_user_input["email"]

    assert %{"data" => %{"createUser" => %{"user" => %{"email" => ^email}}}} =
             json_response(response, 200)

    invited_user = Repo.get_by(OmegaBravera.Accounts.User, email: email)

    assert Decimal.cmp(OmegaBravera.Points.total_points(inviter.id), Decimal.new(30)) == :eq

    assert Decimal.cmp(OmegaBravera.Points.total_points(invited_user.id), Decimal.new(15)) ==
             :eq
  end
end
