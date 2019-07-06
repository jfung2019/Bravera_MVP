defmodule OmegaBravera.Offers.OfferChallengeTeamMembers do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.{
    Accounts.User,
    Offers.OfferChallenge,
    Offers.OfferChallengeTeam,
    Offers.OfferChallengeTeamInvitation
  }

  @primary_key {:id, :binary_id, autogenerate: true}

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

  def kick_team_member_changeset(
        team_member,
        %OfferChallenge{
          status: status,
          team: %{id: team_id, users: team_members},
          user_id: challenge_owner_user_id
        },
        %User{id: logged_in_challenge_owner_id}
      ) do
    team_member
    |> validate_challenge_owner(challenge_owner_user_id, logged_in_challenge_owner_id)
    |> validate_team_member(team_members, team_member_user_id, team_id)
    |> validate_challenge_status(status)
    |> validate_required([:user_id, :team_id])
  end

  def validate_challenge_owner(changeset, challenge_owner_user_id, logged_in_challenge_owner_id) do
    if challenge_owner_user_id != logged_in_challenge_owner_id do
      add_error(changeset, :team_id, "Challenge owner is not correct!")
    else
      changeset
    end
  end

  def validate_team_member(changeset, team_members, team_member_user_id, team_id) do
    result = Enum.find(team_members, &(&1.id == team_member_user_id))

    if not is_nil(result) and result > 0 do
      changeset
      |> put_change(:user_id, team_member_user_id)
      |> put_change(:team_id, team_id)
    else
      add_error(changeset, :user_id, "Team member not found in team!")
    end
  end

  def validate_challenge_status(changeset, status) do
    cond do
      status == "active" -> changeset
      status == "pre_registration" -> changeset
      status == "complete" -> add_error(changeset, :team_id, "Cannot kick team member from complete challenge.")
      status == "expired" -> add_error(changeset, :team_id, "Cannot kick team member from expired challenge.")
    end
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
