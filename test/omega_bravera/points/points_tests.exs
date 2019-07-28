defmodule OmegaBravera.Points.PointsTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Points.Point

  describe "create points from activity data" do
    test "activity_points_changeset/2 is valid when correct data is given" do
      activity = insert(:activity_accumulator, %{distance: Decimal.new(50)})

      assert Point.activity_points_changeset(%Point{}, activity).valid?
    end

    test "activity_points_changeset/2 excludes cycle/ride/virtualride activities" do
      activity1 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Ride",
          distance: Decimal.new(50)
        })

      activity2 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "Cycle",
          distance: Decimal.new(50)
        })

      activity3 =
        insert(:activity_accumulator, %{
          strava_id: Enum.random(10_000_000..20_000_000),
          type: "VirtualRide",
          distance: Decimal.new(50)
        })

      refute Point.activity_points_changeset(%Point{}, activity1).valid?
      refute Point.activity_points_changeset(%Point{}, activity2).valid?
      refute Point.activity_points_changeset(%Point{}, activity3).valid?
    end

    test "activity_points_changeset/2 multiplies activity distance by 10 to fill balance" do
      activity = insert(:activity_accumulator, %{distance: Decimal.new(50)})
      changeset = Point.activity_points_changeset(%Point{}, activity)
      assert changeset.valid?
      assert %{changes: %{balance: 500}} = changeset
    end

    test "activity_points_changeset/2 will reject activities of distance less than 1KM" do
      activity = insert(:activity_accumulator, %{distance: Decimal.from_float(0.9)})
      changeset = Point.activity_points_changeset(%Point{}, activity)
      refute changeset.valid?
      assert %{errors: [balance: _, id: {"Activity's distance is less than 1KM", []}]} = changeset
    end
  end
end
