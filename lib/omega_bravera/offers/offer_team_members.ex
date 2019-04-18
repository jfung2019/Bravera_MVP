defmodule OmegaBravera.Offers.OfferChallengeTeamMembers do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{
    Accounts.User,
    Offers.OfferChallengeTeam,
    Offers.OfferChallengeTeamInvitation
  }

  @primary_key false

  schema "offer_team_members" do
    belongs_to(:user, User)
    belongs_to(:team, OfferChallengeTeam)
  end

  def changeset(team_member, invitation, team, current_user, challenge_owner, params \\ %{}) do
    team_member
    |> cast(params, [:user_id, :team_id])
    |> verify_invitee_not_team_owner(current_user, challenge_owner)
    |> verify_team(invitation, team)
    |> validate_required([:user_id, :team_id])
  end

  # Make sure challenge owner cannot invite himself.
  defp verify_invitee_not_team_owner(%Ecto.Changeset{} = changeset, nil, _),
    do: add_error(changeset, :user_id, "Current user not logged in.")

  defp verify_invitee_not_team_owner(
         %Ecto.Changeset{} = changeset,
         %User{} = current_user,
         %User{} = challenge_owner
       ) do
    if current_user.id == challenge_owner.id do
      add_error(changeset, :user_id, "A team owner cannot invite himself to team.")
    else
      put_change(changeset, :user_id, current_user.id)
    end
  end

  defp verify_team(%Ecto.Changeset{} = changeset, nil, _),
    do: add_error(changeset, :team_id, "Invitation not found in DB.")

  defp verify_team(%Ecto.Changeset{} = changeset, _, nil),
    do: add_error(changeset, :team_id, "Challenge has no team.")

  defp verify_team(
         %Ecto.Changeset{} = changeset,
         %OfferChallengeTeamInvitation{team_id: invitation_team_id},
         %OfferChallengeTeam{id: team_id}
       ) do
    if invitation_team_id == team_id do
      put_change(changeset, :team_id, team_id)
    else
      add_error(changeset, :team_id, "Wrong invitation.")
    end
  end
end
