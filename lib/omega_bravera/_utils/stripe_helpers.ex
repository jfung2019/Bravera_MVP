defmodule OmegaBravera.StripeHelpers do
  require Logger
  alias OmegaBravera.Stripe
  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Money

  # TODO fix this charge thing

  def charge_multiple_donations(donations) do
    Enum.each donations, fn donation ->

      %{
        amount: amount,
        currency: currency,
        ngo_id: ngo_id,
        user_id: user_id
        } = donation

      %{cus_id: customer} = Stripe.get_user_str_customer(user_id)

      %{"name" => ngo_name, "stripe_id" => ngo_connected_acct} = Fundraisers.get_ngo!(ngo_id)

      description = "Donation to " <> ngo_name <> " via Bravera"

      charge_params = %{
        "amount" => total_amount(amount),
        "currency" => currency,
        "customer" => customer,
        "description" => description,
        "destination[account]" => ngo_connected_acct,
        "destination[amount]" => destination_amount(amount)
      }

      case Stripy.req(:post, "charges", charge_params) do
        {:ok, response} ->
          %{body: response_body} = response
          body = Poison.decode!(response_body)

          cond do
            body["source"] ->
              Logger.info fn ->
                "Stripe customer charged: #{inspect(body)}"
              end

              Money.update_donation(donation, %{status: "charged"})

              :ok

            body["error"] ->
              Logger.error fn ->
                "Stripe charge failed: #{inspect(body)}"
              end
              :error
          end
        {:error, reason} ->
          Logger.error fn ->
            "Stripe request failed: #{inspect(reason)}"
          end
          :error
      end

    end
  end

  def charge_stripe_customer(ngo, params) do
    %{"name" => ngo_name, "stripe_id" => ngo_connected_acct} = ngo

    %{"amount" => amount, "currency" => currency, "customer" => customer} = params

    description = "Donation to " <> ngo_name <> " via Bravera"

    charge_params = %{
      "amount" => total_amount(amount),
      "currency" => currency,
      "customer" => customer,
      "description" => description,
      "destination[account]" => ngo_connected_acct,
      "destination[amount]" => destination_amount(amount)
    }

    case Stripy.req(:post, "charges", charge_params) do
      {:ok, response} ->
        %{body: response_body} = response
        body = Poison.decode!(response_body)

        cond do
          body["source"] ->
            Logger.info fn ->
              "Stripe customer charged: #{inspect(body)}"
            end
            :ok

          body["error"] ->
            Logger.error fn ->
              "Stripe charge failed: #{inspect(body)}"
            end
            :error
        end
      {:error, reason} ->
        Logger.error fn ->
          "Stripe request failed: #{inspect(reason)}"
        end
        :error
    end
  end

  #  Create a Stripe customer with Credit Card payment source
  #
  # TODO fix up error and response handling below

  def create_stripe_customer(email, src_id, user_id) do
    case Stripy.req(:post, "customers", %{"email" => email, "source" => src_id, "metadata[user_id]" => user_id})  do
    {:ok, response} ->
      %{body: response_body} = response
      body = Poison.decode!(response_body)

    {:error, reason} ->
      IO.inspect(reason)
    end
  end

  defp centify(amount) do
    amount
    |> Decimal.new
    |> Numbers.mult(100)
  end

  defp total_amount(amount) do
    amount
    |> centify
    |> Decimal.round
    |> Decimal.to_string
  end

  defp destination_amount(amount) do
    amount
    |> centify
    |> Numbers.mult(0.90)
    |> Decimal.round
    |> Decimal.to_string
  end

end
