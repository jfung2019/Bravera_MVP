defmodule OmegaBravera.Challenges.TeamMembers do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Challenges.Team}

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "team_members" do
    belongs_to(:user, User)
    belongs_to(:team, Team)
  end

  def changeset(team_member, params \\ %{}) do
    team_member
    |> cast(params, [:user_id, :team_id])
    |> validate_required([:user_id, :team_id])
  end
end
