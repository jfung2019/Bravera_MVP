defmodule OmegaBravera.TeamsTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.{Challenges, Challenges.Team}

  describe "teams" do
    @valid_attrs %{
      slug: "some-unique-slug-123",
      name: "some name",
      challenge_id: nil,
      user_id: nil
    }

    def team_fixture(attrs \\ %{}) do
      challenge = insert(:ngo_challenge)

      {:ok, team} =
        attrs
        |> Enum.into(%{@valid_attrs | challenge_id: challenge.id, user_id: challenge.user_id})
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
      challenge = insert(:ngo_challenge)

      assert {:ok, %Team{} = team} =
               Challenges.create_team(%{
                 @valid_attrs
                 | challenge_id: challenge.id,
                   user_id: challenge.user_id
               })

      assert team.name == "some name"
      assert team.slug == "some-unique-slug-123"
      assert team.challenge_id == challenge.id
      assert team.user_id == challenge.user_id
    end

    test "create_team/1 refuses team if slug exist in db" do
      challenge = insert(:ngo_challenge)
      attrs = %{@valid_attrs | challenge_id: challenge.id, user_id: challenge.user_id}
      assert {:ok, %Team{} = team} = Challenges.create_team(attrs)
      assert {:error, %Ecto.Changeset{}} = Challenges.create_team(attrs)
    end

    test "create_team/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Challenges.create_team(%{})
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
