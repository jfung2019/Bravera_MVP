defmodule OmegaBraveraWeb.Api.Query.AccountTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{
    Accounts,
    Points,
    Notifications,
    Activity.Activities,
    Trackers,
    Fixtures
  }

  @email "sheriefalaa.w@gmail.com"

  @query """
  query {
    userProfile {
      id
      email
      emailVerified
      firstname
      lastname
      totalKilometersToday
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

  @home_in_app_noti """
  query {
    homeInAppNoti {
      newOffer
      newGroup
      expiringReward
    }
  }
  """

  @list_email_categories """
  query {
    listEmailCategories {
      title
      description
      permitted
    }
  }
  """

  @get_user_sync_method """
  query {
    getUserSyncingMethod {
      syncType
      stravaConnected
    }
  }
  """

  setup %{conn: conn} do
    user = insert(:user, %{email: @email})
    credential = Fixtures.credential_fixture(user.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)
    {:ok, user: user, conn: put_req_header(conn, "authorization", "Bearer #{auth_token}")}
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
                 "lastname" => ^last_name,
                 "totalKilometersToday" => 0.0
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

  test "can get future rewards", %{conn: conn} do
    response = post(conn, "/api", %{query: @future_rewards_query})
    %{"data" => %{"futureRedeems" => []}} = json_response(response, 200)
  end

  test "can get past rewards", %{conn: conn} do
    response = post(conn, "/api", %{query: @past_rewards_query})
    %{"data" => %{"pastRedeems" => []}} = json_response(response, 200)
  end

  test "can get if there is new offers, groups or expiring rewards", %{conn: conn} do
    response = post(conn, "/api", %{query: @home_in_app_noti})

    %{
      "data" => %{
        "homeInAppNoti" => %{"newOffer" => false, "newGroup" => false, "expiringReward" => false}
      }
    } = json_response(response, 200)
  end

  test "can get email categories", %{conn: conn} do
    Notifications.create_email_category(%{
      title: "Platform Notifications",
      description: "Platform Notifications"
    })

    Notifications.create_email_category(%{title: "Activity", description: "Activity"})
    response = post(conn, "/api", %{query: @list_email_categories})

    assert %{"data" => %{"listEmailCategories" => category_list}} = json_response(response, 200)

    assert %{"title" => "Activity", "description" => "Activity", "permitted" => false} in category_list

    assert %{
             "title" => "Platform Notifications",
             "description" => "Platform Notifications",
             "permitted" => true
           } in category_list
  end

  test "can get sync method", %{conn: conn} do
    response = post(conn, "/api", %{query: @get_user_sync_method})

    assert %{
             "data" => %{
               "getUserSyncingMethod" => %{
                 "stravaConnected" => false,
                 "syncType" => "DEVICE"
               }
             }
           } = json_response(response, 200)
  end
end
