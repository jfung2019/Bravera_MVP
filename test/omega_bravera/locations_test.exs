defmodule OmegaBravera.LocationsTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.{Fixtures, Locations, Locations.Location}

  describe "location" do
    test "create_location/1 with valid data creates a location" do
      assert {:ok, %Location{} = location} =
               Locations.create_location(%{name_en: "some name_en", name_zh: "some name_zh"})

      assert location.name_en == "some name_en"
      assert location.name_zh == "some name_zh"
    end

    test "create_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Locations.create_location(%{name_en: nil, name_zh: nil})
    end
  end

  describe "location created" do
    setup do
      {:ok, location: Fixtures.location_fixture()}
    end

    test "list_locations/0 returns all locations", %{location: location} do
      assert location in Locations.list_locations()
    end

    test "get_location!/1 returns the location with given id", %{location: location} do
      assert Locations.get_location!(location.id) == location
    end

    test "update_location/2 with valid data updates the location", %{location: location} do
      assert {:ok, %Location{} = location} =
               Locations.update_location(location, %{
                 name_en: "some updated name_en",
                 name_zh: "some updated name_zh"
               })

      assert location.name_en == "some updated name_en"
      assert location.name_zh == "some updated name_zh"
    end

    test "update_location/2 with invalid data returns error changeset", %{location: location} do
      assert {:error, %Ecto.Changeset{}} =
               Locations.update_location(location, %{name_en: nil, name_zh: nil})

      assert location == Locations.get_location!(location.id)
    end

    test "delete_location/1 deletes the location", %{location: location} do
      assert {:ok, %Location{}} = Locations.delete_location(location)
      assert_raise Ecto.NoResultsError, fn -> Locations.get_location!(location.id) end
    end

    test "change_location/1 returns a location changeset", %{location: location} do
      assert %Ecto.Changeset{} = Locations.change_location(location)
    end
  end
end
