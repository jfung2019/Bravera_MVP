defmodule OmegaBravera.Referrals.Referral do
  use Ecto.Schema
  import Ecto.Changeset

  schema "referrals" do
    field :bonus_points, :integer, default: 10
    field :status, :string, default: "pending_acceptance"
    field :token, :string

    belongs_to(:user, OmegaBravera.Accounts.User)
    belongs_to(:referred_user, OmegaBravera.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(referral, attrs) do
    referral
    |> cast(attrs, [:bonus_points])
    |> put_change(:token, gen_token())
    |> validate_required([:status, :token, :bonus_points])
  end

  def accept_referral_changeset(%__MODULE__{} = referral, %OmegaBravera.Accounts.User{} = referred_user) do
    referral
    |> cast(%{}, [])
    |> put_change(:status, "accepted")
    |> put_change(:referred_user_id, referred_user.id)
    |> validate_required([:status, :referred_user_id])
  end

  def accept_referral_changeset(%__MODULE__{} = referral, _) do
    referral
    |> cast(%{}, [])
    |> add_error(:referred_user_id, "Referred user not found or did not register")
  end

  defp gen_token(length \\ 16), do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
