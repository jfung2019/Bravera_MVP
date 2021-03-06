defmodule OmegaBravera.StripeHelpers do
  require Logger
  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Money
  alias OmegaBravera.Accounts

  alias Decimal
  alias Numbers

  # TODO fix this charge thing

  def charge_multiple_donations(donations) do
    Enum.each(donations, fn donation ->
      %{
        amount: amount,
        currency: currency,
        ngo_id: ngo_id,
        user_id: user_id,
        str_cust_id: customer
      } = donation

      %{"name" => ngo_name} = Fundraisers.get_ngo!(ngo_id)

      %{email: recpt_email} = Accounts.get_user!(user_id)

      description = "Donation to " <> ngo_name <> " via Bravera.co"

      charge_params = %{
        "amount" => total_amount(amount),
        "currency" => currency,
        "customer" => customer,
        "description" => description,
        "receipt_email" => recpt_email
      }

      case Stripy.req(:post, "charges", charge_params) do
        {:ok, response} ->
          %{body: response_body} = response
          body = Poison.decode!(response_body)

          cond do
            body["source"] ->
              Logger.info(fn ->
                "Stripe customer charged: #{inspect(body)}"
              end)

              Money.update_donation(donation, %{status: "charged"})

              :ok

            body["error"] ->
              Logger.error(fn ->
                "Stripe charge failed: #{inspect(body)}"
              end)

              :error
          end

        {:error, reason} ->
          Logger.error(fn ->
            "Stripe request failed: #{inspect(reason)}"
          end)

          :error
      end
    end)
  end

  def charge_stripe_customer(ngo, params) do
    %{name: ngo_name} = ngo

    %{
      "amount" => amount,
      "currency" => currency,
      "customer" => customer,
      "receipt_email" => email
    } = params

    description = "Donation to " <> ngo_name <> " via Bravera.co"

    charge_params = %{
      "amount" => total_amount(amount),
      "currency" => currency,
      "customer" => customer,
      "description" => description,
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
              "Stripe customer charged: #{inspect(body)}"
            end)

            {:ok, response, get_stripe_exchange_rate(body)}

          body["error"] ->
            Logger.error(fn ->
              "Stripe charge failed: #{inspect(body)}"
            end)

            :error
        end

      {:error, reason} ->
        Logger.error(fn ->
          "Stripe request failed: #{inspect(reason)}"
        end)

        :error
    end
  end

  defp get_stripe_exchange_rate(%{"balance_transaction" => balance_transaction}) do
    %{"exchange_rate" => exchange_rate} = balance_transaction

    exchange_rate =
      case exchange_rate do
        nil -> Decimal.new(1)
        _ -> Decimal.new(exchange_rate)
      end

    exchange_rate
  end

  def create_stripe_customer(%{"email" => email, "str_src" => src_id} = params) do
    donor = Accounts.insert_or_return_email_donor(params)

    case Stripy.req(:post, "customers", %{
           "email" => email,
           "source" => src_id,
           "metadata[user_id]" => donor.id
         }) do
      {:ok, %{body: response_body}} ->
        Poison.decode!(response_body)

      {:error, reason} ->
        Logger.error("Stripe request failed: #{inspect(reason)}")
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
end
