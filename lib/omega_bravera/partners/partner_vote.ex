defmodule OmegaBravera.Partners.PartnerVote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "partner_votes" do
    belongs_to :partner, OmegaBravera.Partners.Partner
    belongs_to :user, OmegaBravera.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(partner_vote, attrs) do
    partner_vote
    |> cast(attrs, [:partner_id, :user_id])
    |> validate_required([:partner_id, :user_id])
    |> unique_constraint(:partner_id, name: :partner_votes_partner_id_user_id_index)
  end
end
