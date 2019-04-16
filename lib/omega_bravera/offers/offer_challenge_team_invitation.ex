defmodule OmegaBravera.Offers.OfferChallengeTeamInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Offers.OfferChallengeTeam

  @allowed_attributes [:team_id, :email, :invitee_name]

  schema "offer_challenge_team_invitations" do
    field(:token, :string)
    field(:email, :string)
    field(:invitee_name, :string)
    # Can be: accepted or cancelled or pending_acceptance
    field(:status, :string, default: "pending_acceptance")

    belongs_to(:team, OfferChallengeTeam, foreign_key: :offer_challenge_team_id)

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

  def invitation_cancelled_changeset(team_invitation) do
    team_invitation
    |> cast(%{status: "cancelled"}, [:status])
  end

  def invitation_resent_changeset(team_invitation) do
    team_invitation
    |> change(%{updated_at: Timex.now()})
  end

  defp gen_unique_string(length \\ 8),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
