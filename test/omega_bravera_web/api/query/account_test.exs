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

  @future_rewards_query """
  query {
    futureRedeems {
      insertedAt
      offer {
        name
      }
      offerChallenge {
        id
      }
      status
      token
      updatedAt
    }
  }
  """

  @past_rewards_query """
  query {
    pastRedeems {
      insertedAt
      offer {
        name
      }
      offerChallenge {
        id
      }
      status
      token
      updatedAt
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

  setup %{conn: conn} do
    credential = credential_fixture()
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     user: credential.user, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
  end

  test "user_profile can get all of the users info", %{
    conn: conn,
    user: %{firstname: first_name, lastname: last_name}
  } do
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

  test "can refresh token", %{conn: conn, user: %{firstname: first_name}} do
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

  test "can get live challenges from a user", %{conn: conn, user: user} do
    %{id: challenge_id} = insert(:offer_challenge, user: user, status: "active")
    response = post(conn, "/api", %{query: @user_live_challenges_query})

    assert %{"data" => %{"userLiveChallenges" => [%{"id" => ^challenge_id}]}} =
             json_response(response, 200)
  end

  test "can get points balance from current user", %{conn: conn} do
    response = post(conn, "/api", %{query: @points_balance_query})

    assert %{"data" => %{"userPointsHistory" => %{"balance" => 0.0, "history" => []}}} =
             json_response(response, 200)
  end

  test "can get future rewards", %{conn: conn} do
    response = post(conn, "/api", %{query: @future_rewards_query})
    %{"data" => %{"futureRedeems" => []}} = json_response(response, 200)
  end

  test "can get past rewards", %{conn: conn} do
    response = post(conn, "/api", %{query: @past_rewards_query})
    %{"data" => %{"pastRedeems" => []}} = json_response(response, 200)
  end
end
