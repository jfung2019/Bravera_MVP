defmodule OmegaBraveraWeb.Api.Query.LeaderboardTest do
  use OmegaBraveraWeb.ConnCase, async: true

  alias OmegaBravera.{Accounts, Activity.Activities, Points, Devices, Locations, Groups}

  @get_partner_leaderboard """
  query($partnerId: ID!){
    getPartnerLeaderboard(partnerId: $partnerId){
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
    now = Timex.now()
    beginning_of_week = Timex.beginning_of_week(now)
    beginning_of_month = Timex.beginning_of_month(now)

    {:ok, %{id: location_id}} =
      Locations.create_location(%{name_en: "location1", name_zh: "location1"})

    {:ok, user1} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "1",
        email: "user1@email.com",
        email_verified: true,
        location_id: location_id
      })

    {:ok, %{create_or_update_device: device1}} =
      Devices.create_device(%{active: true, user_id: user1.id, uuid: "1"})

    {:ok, user2} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "2",
        email: "user2@email.com",
        email_verified: true,
        location_id: location_id
      })

    {:ok, %{create_or_update_device: device2}} =
      Devices.create_device(%{active: true, user_id: user2.id, uuid: "2"})

    {:ok, partner} =
      Groups.create_partner(%{
        name: "partner1",
        introduction: "intro",
        short_description: "times",
        images: ["img"]
      })

    Groups.join_partner(partner.id, user1.id)
    Groups.join_partner(partner.id, user2.id)

    {:ok, activity1} =
      Activities.create_app_activity(
        %{
          start_date: Timex.shift(now, days: -60),
          end_date: Timex.shift(now, days: -59),
          type: "Run",
          distance: Decimal.new(5)
        },
        user1.id,
        device1.id,
        0
      )

    Points.create_points_from_activity(activity1, Accounts.get_user_with_todays_points(user1))

    {:ok, activity2} =
      Activities.create_app_activity(
        %{
          start_date: Timex.shift(beginning_of_week, hours: 1),
          end_date: Timex.shift(beginning_of_week, hours: 2),
          type: "Walk",
          distance: Decimal.new(20)
        },
        user1.id,
        device1.id,
        0
      )

    Points.create_points_from_activity(activity2, Accounts.get_user_with_todays_points(user1))

    {:ok, activity3} =
      Activities.create_app_activity(
        %{
          start_date: Timex.shift(beginning_of_month, hours: 1),
          end_date: Timex.shift(beginning_of_month, hours: 2),
          type: "Run",
          distance: Decimal.new(5)
        },
        user1.id,
        device1.id,
        0
      )

    Points.create_points_from_activity(activity3, Accounts.get_user_with_todays_points(user1))

    {:ok, activity4} =
      Activities.create_app_activity(
        %{
          start_date: Timex.shift(now, days: -60),
          end_date: Timex.shift(now, days: -59),
          type: "Run",
          distance: Decimal.new(30)
        },
        user2.id,
        device2.id,
        0
      )

    Points.create_points_from_activity(activity4, Accounts.get_user_with_todays_points(user2))

    {:ok, activity5} =
      Activities.create_app_activity(
        %{
          start_date: Timex.shift(beginning_of_week, hours: 1),
          end_date: Timex.shift(beginning_of_week, hours: 2),
          type: "Walk",
          distance: Decimal.new(5)
        },
        user2.id,
        device2.id,
        0
      )

    Points.create_points_from_activity(activity5, Accounts.get_user_with_todays_points(user2))

    {:ok, activity6} =
      Activities.create_app_activity(
        %{
          start_date: Timex.shift(beginning_of_month, hours: 1),
          end_date: Timex.shift(beginning_of_month, hours: 2),
          type: "Run",
          distance: Decimal.new(10)
        },
        user2.id,
        device2.id,
        0
      )

    Points.create_points_from_activity(activity6, Accounts.get_user_with_todays_points(user2))

    {:ok, conn: conn, user1: user1, user2: user2, partner: partner}
  end

  @tag :skip
  test "can get partner's leaderboard", %{
    conn: conn,
    partner: %{id: partner_id},
    user1: %{id: user1_id},
    user2: %{id: user2_id}
  } do
    conn =
      post(conn, "/api", %{
        query: @get_partner_leaderboard,
        variables: %{"partnerId" => partner_id}
      })

    user1_id = to_string(user1_id)
    user2_id = to_string(user2_id)

    assert %{
             "data" => %{
               "getPartnerLeaderboard" => %{
                 "allTime" => [
                   %{"id" => ^user2_id, "totalKilometers" => 45.0, "totalPoints" => 160.0},
                   %{"id" => ^user1_id, "totalKilometers" => 30.0, "totalPoints" => 130.0}
                 ],
                 "thisMonth" => [
                   %{
                     "id" => ^user1_id,
                     "totalKilometersThisMonth" => 25.0,
                     "totalPointsThisMonth" => 130.0
                   },
                   %{
                     "id" => ^user2_id,
                     "totalKilometersThisMonth" => 15.0,
                     "totalPointsThisMonth" => 160.0
                   }
                 ],
                 "thisWeek" => [
                   %{
                     "id" => ^user1_id,
                     "totalKilometersThisWeek" => 20.0,
                     "totalPointsThisWeek" => 130.0
                   },
                   %{
                     "id" => ^user2_id,
                     "totalKilometersThisWeek" => 5.0,
                     "totalPointsThisWeek" => 160.0
                   }
                 ]
               }
             }
           } = json_response(conn, 200)
  end
end
