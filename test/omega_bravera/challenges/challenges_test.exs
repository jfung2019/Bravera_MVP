defmodule OmegaBravera.ChallengesTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.Challenges

  describe "ngo_chals" do
    alias OmegaBravera.Challenges.NGOChal

    @valid_attrs %{activity: "some activity", distance_target: "120.5", duration: 42, money_target: "120.5", slug: "some slug", start_date: "2010-04-17 14:00:00.000000Z", status: "some status"}
    @update_attrs %{activity: "some updated activity", distance_target: "456.7", duration: 43, money_target: "456.7", slug: "some updated slug", start_date: "2011-05-18 15:01:01.000000Z", status: "some updated status"}
    @invalid_attrs %{activity: nil, distance_target: nil, duration: nil, money_target: nil, slug: nil, start_date: nil, status: nil}

    def ngo_chal_fixture(attrs \\ %{}) do
      {:ok, ngo_chal} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Challenges.create_ngo_chal()

      ngo_chal
    end

    test "list_ngo_chals/0 returns all ngo_chals" do
      ngo_chal = ngo_chal_fixture()
      assert Challenges.list_ngo_chals() == [ngo_chal]
    end

    test "get_ngo_chal!/1 returns the ngo_chal with given id" do
      ngo_chal = ngo_chal_fixture()
      assert Challenges.get_ngo_chal!(ngo_chal.id) == ngo_chal
    end

    test "create_ngo_chal/1 with valid data creates a ngo_chal" do
      assert {:ok, %NGOChal{} = ngo_chal} = Challenges.create_ngo_chal(@valid_attrs)
      assert ngo_chal.activity == "some activity"
      assert ngo_chal.distance_target == Decimal.new("120.5")
      assert ngo_chal.duration == 42
      assert ngo_chal.money_target == Decimal.new("120.5")
      assert ngo_chal.slug == "some slug"
      assert ngo_chal.start_date == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert ngo_chal.status == "some status"
    end

    test "create_ngo_chal/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Challenges.create_ngo_chal(@invalid_attrs)
    end

    test "update_ngo_chal/2 with valid data updates the ngo_chal" do
      ngo_chal = ngo_chal_fixture()
      assert {:ok, ngo_chal} = Challenges.update_ngo_chal(ngo_chal, @update_attrs)
      assert %NGOChal{} = ngo_chal
      assert ngo_chal.activity == "some updated activity"
      assert ngo_chal.distance_target == Decimal.new("456.7")
      assert ngo_chal.duration == 43
      assert ngo_chal.money_target == Decimal.new("456.7")
      assert ngo_chal.slug == "some updated slug"
      assert ngo_chal.start_date == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert ngo_chal.status == "some updated status"
    end

    test "update_ngo_chal/2 with invalid data returns error changeset" do
      ngo_chal = ngo_chal_fixture()
      assert {:error, %Ecto.Changeset{}} = Challenges.update_ngo_chal(ngo_chal, @invalid_attrs)
      assert ngo_chal == Challenges.get_ngo_chal!(ngo_chal.id)
    end

    test "delete_ngo_chal/1 deletes the ngo_chal" do
      ngo_chal = ngo_chal_fixture()
      assert {:ok, %NGOChal{}} = Challenges.delete_ngo_chal(ngo_chal)
      assert_raise Ecto.NoResultsError, fn -> Challenges.get_ngo_chal!(ngo_chal.id) end
    end

    test "change_ngo_chal/1 returns a ngo_chal changeset" do
      ngo_chal = ngo_chal_fixture()
      assert %Ecto.Changeset{} = Challenges.change_ngo_chal(ngo_chal)
    end
  end

  describe "teams" do
    alias OmegaBravera.Challenges.Team

    @valid_attrs %{activity: "some activity", location: "some location", name: "some name"}
    @update_attrs %{activity: "some updated activity", location: "some updated location", name: "some updated name"}
    @invalid_attrs %{activity: nil, location: nil, name: nil}

    def team_fixture(attrs \\ %{}) do
      {:ok, team} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Challenges.create_team()

      team
    end

    test "list_teams/0 returns all teams" do
      team = team_fixture()
      assert Challenges.list_teams() == [team]
    end

    test "get_team!/1 returns the team with given id" do
      team = team_fixture()
      assert Challenges.get_team!(team.id) == team
    end

    test "create_team/1 with valid data creates a team" do
      assert {:ok, %Team{} = team} = Challenges.create_team(@valid_attrs)
      assert team.activity == "some activity"
      assert team.location == "some location"
      assert team.name == "some name"
    end

    test "create_team/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Challenges.create_team(@invalid_attrs)
    end

    test "update_team/2 with valid data updates the team" do
      team = team_fixture()
      assert {:ok, team} = Challenges.update_team(team, @update_attrs)
      assert %Team{} = team
      assert team.activity == "some updated activity"
      assert team.location == "some updated location"
      assert team.name == "some updated name"
    end

    test "update_team/2 with invalid data returns error changeset" do
      team = team_fixture()
      assert {:error, %Ecto.Changeset{}} = Challenges.update_team(team, @invalid_attrs)
      assert team == Challenges.get_team!(team.id)
    end

    test "delete_team/1 deletes the team" do
      team = team_fixture()
      assert {:ok, %Team{}} = Challenges.delete_team(team)
      assert_raise Ecto.NoResultsError, fn -> Challenges.get_team!(team.id) end
    end

    test "change_team/1 returns a team changeset" do
      team = team_fixture()
      assert %Ecto.Changeset{} = Challenges.change_team(team)
    end
  end
end
