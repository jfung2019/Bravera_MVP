defmodule OmegaBravera.Money.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  alias OmegaBravera.Accounts.User
  alias OmegaBravera.Offers.{OfferChallenge, Offer}

  schema "payments" do
    field(:amount, :decimal)
    field(:currency, :string, default: "hkd")
    field(:status, :string, default: "pending")
    field(:stripe_token, :string)

    # charge successful fields
    field(:charge_id, :string)
    field(:last_digits, :string)
    field(:card_brand, :string)
    field(:charged_description, :string)
    field(:charged_status, :string)
    field(:charged_amount, :decimal)
    field(:charged_at, :utc_datetime)
    field(:exchange_rate, :decimal, default: 1)

    # associations
    belongs_to(:user, User)
    belongs_to(:offer_challenge, OfferChallenge)
    belongs_to(:offer, Offer)

    timestamps(type: :utc_datetime)
  end

  @allowed_attributes [
    :amount,
    :stripe_token
  ]
  @required_attributes [
    :amount,
    :currency,
    :stripe_token,
    :offer_challenge_id,
    :offer_id,
    :user_id
  ]

  @doc false
  def changeset(payment, offer, user, attrs) do
    payment
    |> cast(attrs, @allowed_attributes)
    |> put_change(:user_id, user.id)
    |> put_change(:offer_id, offer.id)
    # |> charge_payment()
    |> validate_required(@required_attributes)
  end

  defp charged_attributes(%Ecto.Changeset{} = changeset, stripe_attributes) do
    changeset
    |> put_change(:charge_id, stripe_attributes["id"])
    |> put_change(:last_digits, get_in(stripe_attributes, ["source", "card", "last4"]))
    |> put_change(:card_brand, get_in(stripe_attributes, ["source", "card", "brand"]))
    |> put_change(:charged_description, stripe_attributes["description"])
    |> put_change(:charged_status, stripe_attributes["status"])
    |> put_change(:charged_amount, moneyfied_stripe_amount(stripe_attributes["amount"]))
    |> put_change(:charged_at, DateTime.from_unix!(stripe_attributes["created"]))
    # |> put_change(:exchange_rate, exchange_rate)
  end

  defp moneyfied_stripe_amount(amount), do: Decimal.from_float(amount / 100)
end
