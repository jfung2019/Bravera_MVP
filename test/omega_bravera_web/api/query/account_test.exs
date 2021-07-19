defmodule OmegaBraveraWeb.Api.Query.AccountTest do
  use OmegaBraveraWeb.ConnCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.{
    Repo,
    Accounts,
    Points,
    Accounts.Credential,
    Notifications,
    Activity.Activities,
    Trackers
  }

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
      totalKilometersToday
    }
  }
  """

  @user_profile_with_last_sync_data """
  query($lastSync: String!) {
    userProfileWithLastSyncData(lastSync: $lastSync) {
      lastSyncTotalPoints
      lastSyncTotalKilometers
      userProfile {
        id
        totalPoints
        totalKilometers
        strava {
          athleteId
        }
      }
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
                 "lastname" => ^last_name,
                 "totalKilometersToday" => 0.0
               }
             }
           } = json_response(response, 200)
  end

  test "can get user_profile with last login kms and points", %{
    conn: conn,
    user: %{id: user_id} = user
  } do
    now = Timex.now()

    Trackers.create_strava(user_id, %{
      firstname: "first",
      lastname: "last",
      athlete_id: 1234,
      token: "abc"
    })

    {:ok, activity1} =
      Activities.create_activity(
        %Strava.DetailedActivity{
          id: 1,
          start_date: Timex.shift(now, days: -60),
          type: "Run",
          distance: Decimal.new(5000)
        },
        user
      )

    Points.create_points_from_activity(activity1, Accounts.get_user_with_todays_points(user.id))

    {:ok, activity2} =
      Activities.create_activity(
        %Strava.DetailedActivity{
          id: 2,
          start_date: Timex.shift(now, hours: -2),
          type: "Walk",
          distance: Decimal.new(20000)
        },
        user
      )

    Points.create_points_from_activity(activity2, Accounts.get_user_with_todays_points(user.id))

    last_sync =
      now
      |> Timex.shift(hours: -4)
      |> DateTime.to_iso8601()

    response =
      post(conn, "/api", %{
        query: @user_profile_with_last_sync_data,
        variables: %{"lastSync" => last_sync}
      })

    user_id_string = to_string(user_id)

    assert %{
             "data" => %{
               "userProfileWithLastSyncData" => %{
                 "lastSyncTotalKilometers" => 5.0,
                 "lastSyncTotalPoints" => 50.0,
                 "userProfile" => %{
                   "id" => ^user_id_string,
                   "totalKilometers" => 25.0,
                   "totalPoints" => 130.0,
                   "strava" => %{
                     "athleteId" => "1234"
                   }
                 }
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
