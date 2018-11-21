defmodule OmegaBravera.StripeHelpers do
  require Logger
  alias OmegaBravera.Fundraisers
  alias OmegaBravera.Money
  alias OmegaBravera.Challenges
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
        ngo_chal_id: ngo_chal_id,
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
        "destination[account]" => get_connected_account(),
        "destination[amount]" => destination_amount(amount),
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

  def charge_stripe_customer(ngo, params, ngo_chal_id) do
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
      "destination[account]" => get_connected_account,
      "destination[amount]" => destination_amount(amount),
      "receipt_email" => email
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

            {:ok, response}

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

  def create_stripe_customer(%{"email" => email, "str_src" => src_id} = params) do
    donor = Accounts.insert_or_return_email_user(params)

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

  defp destination_amount(amount) do
    amount
    |> centify()
    |> Numbers.mult(0.88)
    |> Decimal.round()
    |> Decimal.to_string()
  end

  defp get_connected_account() do
    Application.get_env(:stripy, :connected_account)
  end
end
