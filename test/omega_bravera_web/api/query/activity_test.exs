defmodule OmegaBraveraWeb.Api.Query.ActivityTest do
  use OmegaBraveraWeb.ConnCase, async: true
  alias OmegaBravera.{Fixtures, Activity.Activities, Devices}
  import OmegaBravera.Factory

  @get_activity_insight """
  query($period: InsightPeriod!, $date: Date!) {
    getActivityInsight(period: $period, date: $date) {
      averageDistance
      totalDistance
      distanceCompare
      distanceByDate {
        date
        distance
      }
    }
  }
  """

  setup %{conn: conn} do
    {:ok, location} =
      OmegaBravera.Locations.create_location(%{
        name_en: "some name_en",
        name_zh: "some name_zh",
        longitude: 90,
        latitude: 30
      })

    user = insert(:user, %{location_id: location.id})
    credential = Fixtures.credential_fixture(user.id)

    {:ok, %{create_or_update_device: device}} =
      Devices.create_device(%{active: true, user_id: user.id, uuid: "1"})

    {:ok, auth_token, _} = OmegaBravera.Guardian.encode_and_sign(credential.user)

    user2 = insert(:user, %{location_id: location.id, username: "user2"})
    create_activities(user, user2, device)

    {:ok,
     conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer #{auth_token}"),
     location: location,
     user: user}
  end

  test "can get activity insight by weekly", %{conn: conn} do
    now = DateTime.truncate(Timex.now(), :second)

    response =
      post(conn, "/api", %{
        query: @get_activity_insight,
        variables: %{"period" => "WEEKLY", "date" => DateTime.to_iso8601(now)}
      })

    assert %{
             "data" => %{
               "getActivityInsight" => %{
                 "averageDistance" => _avg_dist,
                 "totalDistance" => _total_dist,
                 "distanceCompare" => _dist_comp,
                 "distanceByDate" => dist_by_date
               }
             }
           } = json_response(response, 200)

    assert 7 = length(dist_by_date)
  end

  test "can get activity insight by monthly", %{conn: conn} do
    now = DateTime.truncate(Timex.now(), :second)

    response =
      post(conn, "/api", %{
        query: @get_activity_insight,
        variables: %{"period" => "MONTHLY", "date" => DateTime.to_iso8601(now)}
      })

    assert %{
             "data" => %{
               "getActivityInsight" => %{
                 "averageDistance" => _avg_dist,
                 "totalDistance" => _total_dist,
                 "distanceCompare" => _dist_comp,
                 "distanceByDate" => dist_by_date
               }
             }
           } = json_response(response, 200)

    period_length = Timex.diff(Timex.end_of_month(now), Timex.beginning_of_month(now), :days) + 1
    assert ^period_length = length(dist_by_date)
  end

  test "can get activity insight by yearly", %{conn: conn} do
    now = DateTime.truncate(Timex.now(), :second)

    response =
      post(conn, "/api", %{
        query: @get_activity_insight,
        variables: %{"period" => "YEARLY", "date" => DateTime.to_iso8601(now)}
      })

    assert %{
             "data" => %{
               "getActivityInsight" => %{
                 "averageDistance" => _avg_dist,
                 "totalDistance" => _total_dist,
                 "distanceCompare" => _dist_comp,
                 "distanceByDate" => dist_by_date
               }
             }
           } = json_response(response, 200)

    period_length = Timex.diff(Timex.end_of_year(now), Timex.beginning_of_year(now), :months) + 1
    assert ^period_length = length(dist_by_date)
  end

  defp create_activities(user, user2, device) do
    now = Timex.now()
    beginning_of_week = Timex.beginning_of_week(now)
    beginning_of_month = Timex.beginning_of_month(now)
    beginning_of_year = Timex.beginning_of_year(now)

    # another user's activity
    Activities.create_app_activity(
      %{
        start_date: Timex.shift(beginning_of_week, hours: 1),
        end_date: Timex.shift(beginning_of_week, hours: 2),
        type: "Walk",
        distance: Decimal.new(20),
        source: "test"
      },
      user2.id,
      device.id
    )

    # weekly
    Activities.create_app_activity(
      %{
        start_date: Timex.shift(beginning_of_week, hours: 1),
        end_date: Timex.shift(beginning_of_week, hours: 2),
        type: "Walk",
        distance: Decimal.new(20),
        source: "test"
      },
      user.id,
      device.id
    )

    Activities.create_app_activity(
      %{
        start_date: Timex.shift(beginning_of_week, hours: 6),
        end_date: Timex.shift(beginning_of_week, hours: 8),
        type: "Walk",
        distance: Decimal.new(5),
        source: "test"
      },
      user.id,
      device.id
    )

    # activity for last week
    Activities.create_app_activity(
      %{
        start_date: Timex.shift(beginning_of_week, hours: -2, days: -2),
        end_date: Timex.shift(beginning_of_week, hours: -1, days: -2),
        type: "Walk",
        distance: Decimal.new(10),
        source: "test"
      },
      user.id,
      device.id
    )

    # last month activity
    Activities.create_app_activity(
      %{
        start_date: Timex.shift(beginning_of_month, hours: -2, days: -2),
        end_date: Timex.shift(beginning_of_month, hours: -1, days: -2),
        type: "Walk",
        distance: Decimal.new(5),
        source: "test"
      },
      user.id,
      device.id
    )

    # last year activity
    Activities.create_app_activity(
      %{
        start_date: Timex.shift(beginning_of_year, hours: -2, days: -2),
        end_date: Timex.shift(beginning_of_year, hours: -1, days: -2),
        type: "Walk",
        distance: Decimal.new(50),
        source: "test"
      },
      user.id,
      device.id
    )
  end
end
