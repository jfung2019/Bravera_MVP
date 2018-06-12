defmodule OmegaBravera.TrackersTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.Trackers

  describe "stravas" do
    alias OmegaBravera.Trackers.Strava

    @valid_attrs %{athlete_id: 42, email: "some email", firstname: "some firstname", lastname: "some lastname", token: "some token"}
    @update_attrs %{athlete_id: 43, email: "some updated email", firstname: "some updated firstname", lastname: "some updated lastname", token: "some updated token"}
    @invalid_attrs %{athlete_id: nil, email: nil, firstname: nil, lastname: nil, token: nil}

    def strava_fixture(attrs \\ %{}) do
      {:ok, strava} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Trackers.create_strava()

      strava
    end

    test "list_stravas/0 returns all stravas" do
      strava = strava_fixture()
      assert Trackers.list_stravas() == [strava]
    end

    test "get_strava!/1 returns the strava with given id" do
      strava = strava_fixture()
      assert Trackers.get_strava!(strava.id) == strava
    end

    test "create_strava/1 with valid data creates a strava" do
      assert {:ok, %Strava{} = strava} = Trackers.create_strava(@valid_attrs)
      assert strava.athlete_id == 42
      assert strava.email == "some email"
      assert strava.firstname == "some firstname"
      assert strava.lastname == "some lastname"
      assert strava.token == "some token"
    end

    test "create_strava/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Trackers.create_strava(@invalid_attrs)
    end

    test "update_strava/2 with valid data updates the strava" do
      strava = strava_fixture()
      assert {:ok, strava} = Trackers.update_strava(strava, @update_attrs)
      assert %Strava{} = strava
      assert strava.athlete_id == 43
      assert strava.email == "some updated email"
      assert strava.firstname == "some updated firstname"
      assert strava.lastname == "some updated lastname"
      assert strava.token == "some updated token"
    end

    test "update_strava/2 with invalid data returns error changeset" do
      strava = strava_fixture()
      assert {:error, %Ecto.Changeset{}} = Trackers.update_strava(strava, @invalid_attrs)
      assert strava == Trackers.get_strava!(strava.id)
    end

    test "delete_strava/1 deletes the strava" do
      strava = strava_fixture()
      assert {:ok, %Strava{}} = Trackers.delete_strava(strava)
      assert_raise Ecto.NoResultsError, fn -> Trackers.get_strava!(strava.id) end
    end

    test "change_strava/1 returns a strava changeset" do
      strava = strava_fixture()
      assert %Ecto.Changeset{} = Trackers.change_strava(strava)
    end
  end
end
