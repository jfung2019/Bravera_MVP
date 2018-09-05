defmodule OmegaBravera.TrackersTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.{Accounts, Trackers}

  describe "stravas" do
    alias OmegaBravera.Trackers.Strava

    @valid_attrs %{athlete_id: 42, email: "someone@email.com", firstname: "firstname", lastname: "lastname", token: "token"}
    @update_attrs %{athlete_id: 43, email: "someone@updatedemail.com", firstname: "updated firstname", lastname: "updated lastname", token: "updated token"}
    @invalid_attrs %{athlete_id: nil, email: nil, firstname: nil, lastname: nil, token: nil}

    def strava_fixture(attrs \\ %{}) do
      changeset_attrs = Map.merge(@valid_attrs, attrs)
      changeset = Strava.changeset(%Strava{}, changeset_attrs)
      {:ok, strava} = Repo.insert(changeset)

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
      {:ok, user} = Accounts.create_user(%{email: "someone@email.com", firstname: "firstname", lastname: "lastname"})
      {:ok, strava} = Trackers.create_strava(user.id, @valid_attrs)


      assert match?(%Trackers.Strava{}, strava) == true

      assert strava.athlete_id == 42
      assert strava.email == "someone@email.com"
      assert strava.firstname == "firstname"
      assert strava.lastname == "lastname"
      assert strava.token == "token"
    end

    test "create_strava/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Trackers.create_strava(@invalid_attrs)
    end

    test "update_strava/2 with valid data updates the strava" do
      strava = strava_fixture()

      assert {:ok, strava} = Trackers.update_strava(strava, @update_attrs)

      assert match?(%Trackers.Strava{}, strava) == true

      assert strava.athlete_id == 43
      assert strava.email == "someone@updatedemail.com"
      assert strava.firstname == "updated firstname"
      assert strava.lastname == "updated lastname"
      assert strava.token == "updated token"
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
