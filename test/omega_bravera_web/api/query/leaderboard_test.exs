defmodule OmegaBraveraWeb.Api.Query.LeaderboardTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Locations, Groups, Fixtures}

  @get_partner_leaderboard """
  query($partnerId: ID!) {
    getPartnerLeaderboard(partnerId: $partnerId) {
      thisWeek{
        id
        totalPointsThisWeek
        totalKilometersThisWeek
      }
      thisMonth{
        id
        totalPointsThisMonth
        totalKilometersThisMonth
      }
      allTime{
        id
        totalPoints
        totalKilometers
      }
    }
  }
  """

  @get_friend_leaderboard """
  query {
    getFriendLeaderboard {
      thisWeek{
        id
        totalPointsThisWeek
        totalKilometersThisWeek
      }
      thisMonth{
        id
        totalPointsThisMonth
        totalKilometersThisMonth
      }
      allTime{
        id
        totalPoints
        totalKilometers
      }
    }
  }
  """

  @get_leaderboard_is_friend """
  query {
    getLeaderboard {
      thisWeek{
        id
        username
        isFriend
      }
    }
  }
  """

  @get_leaderboard """
  query {
    getLeaderboard {
      thisWeek{
        id
        totalPointsThisWeek
        totalKilometersThisWeek
      }
      thisMonth{
        id
        totalPointsThisMonth
        totalKilometersThisMonth
      }
      allTime{
        id
        totalPoints
        totalKilometers
      }
    }
  }
  """

  setup %{conn: conn} do
    {:ok, %{id: location_id}} =
      Locations.create_location(%{
        name_en: "location1",
        name_zh: "location1",
        longitude: 90,
        latitude: 30
      })

    {:ok, user1} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "1",
        email: "user1@email.com",
        email_verified: true,
        location_id: location_id
      })

    {:ok, user2} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "2",
        email: "user2@email.com",
        email_verified: true,
        location_id: location_id
      })

    {:ok, user3} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "3",
        email: "user3@email.com",
        email_verified: true,
        location_id: location_id
      })

    {:ok, user4} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "4",
        email: "user4@email.com",
        email_verified: true,
        location_id: location_id
      })

    {:ok, partner} =
      Groups.create_partner(%{
        name: "partner1",
        introduction: "intro",
        short_description: "times",
        images: ["img"]
      })

    Groups.join_partner(partner.id, user1.id)
    Groups.join_partner(partner.id, user2.id)

    Accounts.create_friend_request(%{receiver_id: user1.id, requester_id: user2.id})
    |> then(fn {:ok, friend} ->
      Accounts.accept_friend_request(friend)
    end)

    Accounts.create_friend_request(%{receiver_id: user1.id, requester_id: user3.id})
    |> then(fn {:ok, friend} ->
      Accounts.accept_friend_request(friend)
    end)

    credential = Fixtures.credential_fixture(user1.id)
    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     user1: user1,
     user2: user2,
     user3: user3,
     user4: user4,
     partner: partner}
  end

  test "has isFriend field", %{conn: conn, user1: user1, user2: user2, user3: user3} do
    conn = post(conn, "/api", %{query: @get_leaderboard_is_friend})

    assert %{
             "data" => %{
               "getLeaderboard" => %{
                 "thisWeek" => this_week_list
               }
             }
           } = json_response(conn, 200)

    # Assert that user 1 is a friend to user2 and user3
    assert %{"isFriend" => true} =
             leaderboard_user3 = Enum.find(this_week_list, %{}, fn u -> u["username"] == user3.username end)

    assert %{"isFriend" => true} =
             leaderboard_user2 = Enum.find(this_week_list, %{}, fn u -> u["username"] == user2.username end)
  end

  test "can get partner's leaderboard", %{conn: conn, partner: %{id: partner_id}} do
    conn =
      post(conn, "/api", %{
        query: @get_partner_leaderboard,
        variables: %{"partnerId" => partner_id}
      })

    assert %{
             "data" => %{
               "getPartnerLeaderboard" => %{
                 "allTime" => all_time_list,
                 "thisMonth" => this_month_list,
                 "thisWeek" => this_week_list
               }
             }
           } = json_response(conn, 200)

    assert {2, 2, 2} = {length(all_time_list), length(this_month_list), length(this_week_list)}
  end

  test "can get friend leaderboard", %{conn: conn} do
    conn = post(conn, "/api", %{query: @get_friend_leaderboard})

    assert %{
             "data" => %{
               "getFriendLeaderboard" => %{
                 "allTime" => all_time_list,
                 "thisMonth" => this_month_list,
                 "thisWeek" => this_week_list
               }
             }
           } = json_response(conn, 200)

    assert {3, 3, 3} = {length(all_time_list), length(this_month_list), length(this_week_list)}
  end

  test "can get Bravera leaderboard", %{conn: conn} do
    conn = post(conn, "/api", %{query: @get_leaderboard})

    assert %{
             "data" => %{
               "getLeaderboard" => %{
                 "allTime" => all_time_list,
                 "thisMonth" => this_month_list,
                 "thisWeek" => this_week_list
               }
             }
           } = json_response(conn, 200)

    assert {4, 4, 4} = {length(all_time_list), length(this_month_list), length(this_week_list)}
  end

  test "can get Bravera leaderboard without gdpr deleted user", %{
    conn: conn,
    user4: %{id: user4_id}
  } do
    {:ok, _result} = Accounts.gdpr_delete_user(user4_id)

    conn = post(conn, "/api", %{query: @get_leaderboard})

    assert %{
             "data" => %{
               "getLeaderboard" => %{
                 "allTime" => all_time_list,
                 "thisMonth" => this_month_list,
                 "thisWeek" => this_week_list
               }
             }
           } = json_response(conn, 200)

    assert {3, 3, 3} = {length(all_time_list), length(this_month_list), length(this_week_list)}
  end
end
