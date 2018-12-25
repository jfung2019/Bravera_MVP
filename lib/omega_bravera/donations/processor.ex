defmodule OmegaBravera.Donations.Processor do
  require Logger

  alias OmegaBravera.{
    Money,
    Accounts.User,
    StripeHelpers,
    Money.Donation,
    Repo,
    Donations.Notifier,
    Challenges.NGOChal,
    Challenges
  }

  def charge_donation(%Donation{} = dn) do
    donation = Repo.preload(dn, [:ngo, :ngo_chal, :user])

    case StripeHelpers.charge_stripe_customer(
           donation.ngo,
           charge_params(donation, donation.ngo_chal),
           donation.ngo_chal_id
         ) do
      {:ok, %{body: body}, exchange_rate} ->
        case Poison.decode!(body) do
          %{"source" => _} = response ->
            updated =
              donation
              |> Donation.charge_changeset(response, exchange_rate)
              |> Repo.update!()

            Notifier.send_donation_charged_email(updated)

            {:ok, updated}

          %{"error" => _} ->
            {:error, :stripe_error}

          _ ->
            {:error, :unknown_error}
        end

      {:error, reason} ->
        {:error, reason}

      :error ->
        {:error, :unknown_error}
    end
  end

  def charge_donation(_, _) do
    {:ok, :no_kickstarter}
  end

  def charge_params(%Donation{} = donation, %NGOChal{type: "PER_KM"} = challenge) do
    # To get the calculated field distance_covered
    challenge = Challenges.get_ngo_chal!(challenge.id)

    %{
      "amount" => Decimal.mult(donation.amount, challenge.distance_covered) |> total_amount(),
      "currency" => donation.currency,
      "source" => donation.str_src,
      "receipt_email" => donation.user.email,
      "customer" => donation.str_cus_id
    }
  end

  def charge_params(%Donation{} = donation, _) do
    %{
      "amount" => donation.amount |> total_amount(),
      "currency" => donation.currency,
      "source" => donation.str_src,
      "receipt_email" => donation.user.email,
      "customer" => donation.str_cus_id
    }
  end

  defp total_amount(%Decimal{} = amount) do
    gateway = Decimal.mult(amount, Decimal.new(0.034)) |> Decimal.add(Decimal.new(2.35))
    bravera = Decimal.mult(amount, Decimal.new(0.06))

    Decimal.add(gateway, bravera) |> Decimal.add(amount)
  end
end
