defmodule OmegaBravera.Challenges.TeamMembers do
  use Ecto.Schema

  alias OmegaBravera.{Accounts.User, Challenges.Team}

  @primary_key false

  schema "team_members" do
    belongs_to(:user, User)
    belongs_to(:team, Team)
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> Ecto.Changeset.cast(params, [:user_id, :team_id])
    |> Ecto.Changeset.validate_required([:user_id, :team_id])
  end
end
