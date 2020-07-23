defmodule OmegaBravera.Partners.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "partner_members" do
    belongs_to :user, OmegaBravera.Accounts.User
    belongs_to :partner, OmegaBravera.Partners.Partner

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :partner_id])
    |> validate_required([:user_id, :partner_id])
  end
end
