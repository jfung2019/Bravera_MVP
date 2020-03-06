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

  @refresh_token_query """
  query {
    refreshAuthToken {
      token
    }
  }
  """

  @user_live_challenges_query """
  query {
    userLiveChallenges {
      id
    }
  }
  """

  @points_balance_query """
    query {
      userPointsHistory {
        balance
        history {
          posValue
          negValue
          source
          insertedAt
          updatedAt
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

  setup do
    credential = credential_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, token: auth_token, user: credential.user}
  end

  test "user_profile can get all of the users info", %{
    token: token,
    conn: conn,
    user: %{firstname: first_name, lastname: last_name}
  } do
    conn = conn |> put_req_header("authorization", "Bearer #{token}")
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

  test "can refresh token", %{conn: conn, token: token, user: %{firstname: first_name}} do
    conn = conn |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @refresh_token_query})

    assert %{"data" => %{"refreshAuthToken" => %{"token" => new_token}}} =
             json_response(response, 200)

    conn = build_conn() |> put_req_header("authorization", "Bearer #{new_token}")
    response = post(conn, "/api", %{query: @query})

    assert %{
             "data" => %{
               "userProfile" => %{
                 "firstname" => ^first_name
               }
             }
           } = json_response(response, 200)
  end

  test "can get live challenges from a user", %{conn: conn, token: token, user: user} do
    %{id: challenge_id} = insert(:offer_challenge, user: user, status: "active")
    conn = conn |> put_req_header("authorization", "Bearer #{token}")
    response = post(conn, "/api", %{query: @user_live_challenges_query})

    assert %{"data" => %{"userLiveChallenges" => [%{"id" => ^challenge_id}]}} =
             json_response(response, 200)
  end

  test "can get points balance from current user", %{conn: conn, token: token} do
    response =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post("/api", %{query: @points_balance_query})

    assert %{"data" => %{"userPointsHistory" => %{"balance" => 0.0, "history" => []}}} =
             json_response(response, 200)
  end
end
