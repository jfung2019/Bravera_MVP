defmodule OmegaBravera.Money.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  require Logger

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
    :stripe_token
  ]
  @required_attributes [
    :stripe_token,
    :offer_id,
    :user_id
  ]

  @doc false
  def changeset(payment, offer, user, attrs) do
    payment
    |> cast(attrs, @allowed_attributes)
    |> put_change(:user_id, user.id)
    |> put_change(:offer_id, offer.id)
    |> put_change(:amount, offer.payment_amount)
    |> validate_required(@required_attributes)
    |> do_stripe_charge(offer, user, attrs)
  end

  def do_stripe_charge(
        %Ecto.Changeset{valid?: true} = changeset,
        %Offer{slug: slug, payment_amount: amount},
        %User{email: email},
        %{"stripe_token" => stripe_token}
      ) do
    charge_params = %{
      "amount" => total_amount(amount),
      "currency" => "hkd",
      "source" => stripe_token,
      "description" => "Payment for " <> slug <> " via Bravera.co",
      "receipt_email" => email,
      "expand[]" => "balance_transaction"
    }

    case Stripy.req(:post, "charges", charge_params) do
      {:ok, response} ->
        %{body: response_body} = response
        body = Poison.decode!(response_body)

        cond do
          body["source"] ->
            Logger.info(fn ->
              "Offer Payment Successful: #{inspect(body)}"
            end)

            changeset
            |> put_change(:status, "charged")
            |> charged_attributes_changeset(body, get_stripe_exchange_rate(body))

          body["error"] ->
            Logger.error(fn ->
              "Offer Payment Failed: #{inspect(body)}"
            end)

            add_error(changeset, :charge_id, "Could not charge offer payment.")
        end

      {:error, reason} ->
        Logger.error(fn ->
          "Payment: Stripe request failed: #{inspect(reason)}"
        end)

        add_error(changeset, :charge_id, "Request Error.")
    end
  end

  def do_stripe_charge(%Ecto.Changeset{} = changeset, offer, user, token_params) do
    Logger.warn(
      "Changeset: #{inspect(changeset)} offer: #{inspect(offer)} user: #{inspect(user)} token_params: #{inspect(token_params)}"
    )

    add_error(changeset, :id, "do_stripe_charge: bad params, ensure map has strings not atoms.")
  end

  defp charged_attributes_changeset(
         %Ecto.Changeset{} = changeset,
         stripe_attributes,
         exchange_rate
       ) do
    changeset
    |> put_change(:charge_id, stripe_attributes["id"])
    |> put_change(:last_digits, get_in(stripe_attributes, ["source", "card", "last4"]))
    |> put_change(:card_brand, get_in(stripe_attributes, ["source", "card", "brand"]))
    |> put_change(:charged_description, stripe_attributes["description"])
    |> put_change(:charged_status, stripe_attributes["status"])
    |> put_change(:charged_amount, moneyfied_stripe_amount(stripe_attributes["amount"]))
    |> put_change(:charged_at, DateTime.from_unix!(stripe_attributes["created"]))
    |> put_change(:exchange_rate, exchange_rate)
  end

  defp get_stripe_exchange_rate(%{"balance_transaction" => balance_transaction}) do
    %{"exchange_rate" => exchange_rate} = balance_transaction

    case exchange_rate do
      nil -> Decimal.new(1)
      _ -> Decimal.new(exchange_rate)
    end
  end

  defp centify(amount) do
    amount
    |> Decimal.new()
    |> Numbers.mult(100)
  end

  defp total_amount(amount) do
    amount
    |> centify()
    |> Decimal.round()
    |> Decimal.to_string()
  end

  defp moneyfied_stripe_amount(amount), do: Decimal.from_float(amount / 100)
end
