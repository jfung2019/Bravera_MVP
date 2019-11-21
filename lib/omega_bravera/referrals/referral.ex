defmodule OmegaBravera.Referrals.Referral do
  use Ecto.Schema
  import Ecto.Changeset

  schema "referrals" do
    field(:bonus_points, :integer, default: 10)
    # should be removed
    field(:status, :string, default: "pending_acceptance")
    field(:token, :string)

    belongs_to(:user, OmegaBravera.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(referral, attrs) do
    referral
    |> cast(attrs, [:user_id, :bonus_points])
    |> put_change(:token, gen_token())
    |> validate_required([:status, :token, :bonus_points])
  end

  defp gen_token(length \\ 4),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length) |> String.replace("_", "9")
end
