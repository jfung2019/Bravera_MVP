defmodule OmegaBravera.Offers.OfferChallengeTeamInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.OfferChallengeTeam
  alias OmegaBravera.Accounts.User

  @allowed_attributes [:team_id, :email, :invitee_name]

  schema "offer_challenge_team_invitations" do
    field(:token, :string)
    field(:email, :string)
    field(:invitee_name, :string)
    # Can be: accepted or cancelled or pending_acceptance
    field(:status, :string, default: "pending_acceptance")

    belongs_to(:team, OfferChallengeTeam)

    timestamps(type: :utc_datetime)
  end

  def changeset(team_invitation, team, attrs) do
    team_invitation
    |> cast(attrs, @allowed_attributes)
    |> change(%{
      team_id: team.id,
      token: gen_unique_string()
    })
    |> validate_required(@allowed_attributes)
  end

  def invitation_accepted_changeset(team_invitation) do
    team_invitation
    |> cast(%{status: "accepted"}, [:status])
  end

  def invitation_cancelled_changeset(team_invitation, current_user, challenge_owner) do
    team_invitation
    |> cast(%{status: "cancelled"}, [:status])
    |> verify_owner(current_user, challenge_owner)
  end

  def invitation_resent_changeset(team_invitation, current_user, challenge_owner) do
    team_invitation
    |> change(%{updated_at: Timex.now()})
    |> verify_owner(current_user, challenge_owner)
    |> is_resend_recent?()
  end

  defp verify_owner(%Ecto.Changeset{} = changeset, nil, _),
    do: add_error(changeset, :email, "Owner not found, please login.")

  defp verify_owner(
         %Ecto.Changeset{} = changeset,
         %User{} = current_user,
         %User{} = challenge_owner
       ) do
    if current_user.id == challenge_owner.id do
      changeset
    else
      add_error(
        changeset,
        :email,
        "Incorrect Owner. Please login using the challenge owner account."
      )
    end
  end

  defp is_resend_recent?(%Ecto.Changeset{} = changeset) do
    last_updated = get_field(changeset, :updated_at)

    if not is_nil(last_updated) and Timex.before?(Timex.now(), Timex.shift(last_updated, days: 1)) do
      change(changeset, %{updated_at: DateTime.truncate(Timex.now(), :second)})
    else
      add_error(
        changeset,
        :updated_at,
        "Action not allowed. Please wait until invitation is resendable again."
      )
    end
  end

  defp gen_unique_string(length \\ 8),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
