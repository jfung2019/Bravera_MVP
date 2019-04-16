defmodule OmegaBravera.Offers.OfferChallengeTeamMembers do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{Accounts.User, Offers.OfferChallengeTeam}

  @primary_key false

  schema "offer_team_members" do
    belongs_to(:user, User)
    belongs_to(:team, OfferChallengeTeam)
  end

  def changeset(team_member, params \\ %{}) do
    team_member
    |> cast(params, [:user_id, :team_id])
    |> validate_required([:user_id, :team_id])
  end
end
