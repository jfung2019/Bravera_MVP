defmodule OmegaBravera.StripeHelpers do
  require Logger
  alias OmegaBravera.Stripe
  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Money
  alias OmegaBravera.Challenges
  alias OmegaBravera.Accounts

  alias Decimal
  alias Numbers

  # TODO fix this charge thing

  def charge_multiple_donations(donations) do
    Enum.each donations, fn donation ->

      %{
        amount: amount,
        currency: currency,
        ngo_id: ngo_id,
        user_id: user_id,
        ngo_chal_id: ngo_chal_id,
        str_cust_id: customer
        } = donation

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

          ngo_chal = Challenges.get_ngo_chal!(ngo_chal_id)

          %{total_secured: total_secured} = ngo_chal

          new_total = Decimal.add(total_secured, amount)

          Challenges.update_ngo_chal(ngo_chal, %{total_secured: new_total})

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

  def charge_stripe_customer(ngo, params, ngo_chal_id) do
    %{name: ngo_name, stripe_id: ngo_connected_acct} = ngo

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

        ngo_chal = Challenges.get_ngo_chal!(ngo_chal_id)

        %{total_secured: total_secured} = ngo_chal

        new_total = Decimal.add(total_secured, amount)

        Challenges.update_ngo_chal(ngo_chal, %{total_secured: new_total})

        cond do
          body["source"] ->
            Logger.info fn ->
              "Stripe customer charged: #{inspect(body)}"
            end
            {:ok, response}

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

  # TODO Add user creation and relationship below

  def create_stripe_customer(email, src_id) do

    user = Accounts.insert_or_return_email_user(email)

    %{id: user_id} = user

    case Stripy.req(:post, "customers", %{"email" => email, "source" => src_id, "metadata[user_id]" => user_id})  do
    {:ok, response} ->
      %{body: response_body} = response
      body = Poison.decode!(response_body)

    {:error, reason} ->
      Logger.error fn ->
        "Stripe request failed: #{inspect(reason)}"
      end
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
    |> Numbers.mult(0.94)
    |> Decimal.round
    |> Decimal.to_string
  end

end
