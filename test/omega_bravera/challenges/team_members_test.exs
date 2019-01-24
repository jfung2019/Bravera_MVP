defmodule OmegaBravera.TeamMembersTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.{Challenges, Challenges.TeamMembers}

  describe "add_user_to_team/1" do
    test "adds an existing user to an existing team" do
      team = insert(:team)

      new_team_member =
        insert(
          :user,
          %{
            firstname: "Sherief",
            lastname: "Alaa",
            email: "sheriefalaa.w@gmail.com"
          }
        )

      assert {:ok, %TeamMembers{} = team_with_member} =
               Challenges.add_user_to_team(%{user_id: new_team_member.id, team_id: team.id})

      assert team_with_member.team_id == team.id
      assert team_with_member.user_id == new_team_member.id
    end
  end
end
