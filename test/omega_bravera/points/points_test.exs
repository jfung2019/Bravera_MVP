defmodule OmegaBravera.Points.PointsTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Points.Point
  alias OmegaBravera.{Accounts, Points, Repo}

  setup do
    attrs = %{
      firstname: "sherief",
      lastname: "alaa",
      email: "sheriefalaa.w@gmail.com",
      email_verified: true,
      accept_terms: true,
      location_id: 1
    }

    {:ok, user} = Accounts.create_user(attrs)

    {:ok, user: Accounts.get_user_with_todays_points(user)}
  end

  describe "create points from activity data" do
    test "activity_points_changeset/3 is valid when correct data is given", %{user: user} do
      activity =
        insert(:activity_accumulator, %{distance: Decimal.new(50), user: nil, user_id: user.id})

      assert Point.activity_points_changeset(%Point{}, activity, user).valid?
    end

    test "activity_points_changeset/3 excludes cycle/ride/virtualride activities", %{user: user} do
      activity1 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Ride",
          distance: Decimal.new(50),
          user: nil,
          user_id: user.id
        })

      activity2 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Cycle",
          distance: Decimal.new(50),
          user: nil,
          user_id: user.id
        })

      activity3 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "VirtualRide",
          distance: Decimal.new(50),
          user: nil,
          user_id: user.id
        })

      refute Point.activity_points_changeset(%Point{}, activity1, user).valid?
      refute Point.activity_points_changeset(%Point{}, activity2, user).valid?
      refute Point.activity_points_changeset(%Point{}, activity3, user).valid?
    end

    test "activity_points_changeset/3 multiplies activity distance by 10 to fill value", %{
      user: user
    } do
      activity =
        insert(:activity_accumulator, %{distance: Decimal.new(50), user: nil, user_id: user.id})

      changeset = Point.activity_points_changeset(%Point{}, activity, user)
      assert changeset.valid?

      # value is 150 not 500 due to daily_points_limit being equals 15k * Point.@points_per_km (10 points)
      value = Decimal.new(150)
      assert %{changes: %{value: ^value}} = changeset
    end

    test "activity_points_changeset/3 will allow activities of distance less than 1KM", %{
      user: user
    } do
      activity =
        insert(:activity_accumulator, %{
          distance: Decimal.from_float(0.95),
          user: nil,
          user_id: user.id
        })

      changeset = Point.activity_points_changeset(%Point{}, activity, user)
      assert changeset.valid?
      value = Decimal.from_float(9.5) |> Decimal.round(2)
      assert %{changes: %{value: ^value}} = changeset
    end

    test "get_user_with_todays_points/1 counts user's today's points", %{user: user} do
      activity1 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Run",
          distance: Decimal.new(5),
          user: nil,
          user_id: user.id
        })

      Points.create_points_from_activity(activity1, Accounts.get_user_with_todays_points(user))

      activity2 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Walk",
          distance: Decimal.new(5),
          user: nil,
          user_id: user.id
        })

      Points.create_points_from_activity(activity2, Accounts.get_user_with_todays_points(user))

      activity3 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Run",
          distance: Decimal.new(5),
          user: nil,
          user_id: user.id
        })

      Points.create_points_from_activity(activity3, Accounts.get_user_with_todays_points(user))

      updated_user_with_points = Accounts.get_user_with_todays_points(user)

      assert updated_user_with_points.todays_points ==
               Decimal.from_float(150.00) |> Decimal.round(2)
    end

    test "get_user_with_todays_points/1 will only count today's points for a user", %{user: user} do
      now = Timex.now()

      activity1 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Run",
          distance: Decimal.new(10),
          user: nil,
          user_id: user.id
        })

      {:ok, point1} =
        Points.create_points_from_activity(activity1, Accounts.get_user_with_todays_points(user))

      point1
      |> Ecto.Changeset.change(
        inserted_at: DateTime.truncate(Timex.shift(now, days: -5), :second)
      )
      |> Repo.update()

      activity2 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Walk",
          distance: Decimal.new(10),
          user: nil,
          user_id: user.id
        })

      {:ok, point2} =
        Points.create_points_from_activity(activity2, Accounts.get_user_with_todays_points(user))

      point2
      |> Ecto.Changeset.change(inserted_at: DateTime.truncate(Timex.shift(now, days: 5), :second))
      |> Repo.update()

      activity3 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Run",
          distance: Decimal.new(5),
          user: nil,
          start_date: now,
          user_id: user.id
        })

      Points.create_points_from_activity(activity3, Accounts.get_user_with_todays_points(user))

      user_with_points = Accounts.get_user_with_todays_points(user)
      assert user_with_points.todays_points == Decimal.new(50) |> Decimal.round(2)
    end

    test "create_points_from_activity/2 will not add more points than daily_points_limit * points_per_km",
         %{user: user} do
      activity1 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Run",
          distance: Decimal.new(15),
          user: nil,
          user_id: user.id
        })

      Points.create_points_from_activity(activity1, Accounts.get_user_with_todays_points(user))

      activity2 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Walk",
          distance: Decimal.new(10),
          user: nil,
          user_id: user.id
        })

      {:error, reason} =
        Points.create_points_from_activity(activity2, Accounts.get_user_with_todays_points(user))

      updated_user_with_points = Accounts.get_user_with_todays_points(user)
      assert updated_user_with_points.todays_points == Decimal.new(150)
      assert %{errors: [_, id: {"User reached max points for today", []}]} = reason
    end

    # TODO: for the future:

    # test if daily_points_limit is modified, it will take effect. - Sherief.

    # test if negative value will not affect adding points. For example:
    # user X reached daily_points_limit (150 points) but he spent 100 with -100 value.
    # make sure that he still cannot add more points. - Sherief.
  end
end
