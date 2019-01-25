defmodule OmegaBravera.Donations.Processor do
  require Logger

  alias OmegaBravera.{
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
           charge_params(donation, donation.ngo_chal)
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
    distance_covered =
      Challenges.get_ngo_chal!(challenge.id)
      |> truncate_exceeding_distance()

    amount =
      cond do
        donation.donor_pays_fees == true ->
          donation.amount
          |> Decimal.mult(distance_covered)
          |> amount_with_fees()
        donation.donor_pays_fees == false ->
          donation.amount
          |> Decimal.mult(distance_covered)
      end

    %{
      "amount" => amount,
      "currency" => donation.currency,
      "source" => donation.str_src,
      "receipt_email" => donation.user.email,
      "customer" => donation.str_cus_id
    }
  end

  def charge_params(%Donation{} = donation, _) do
    amount =
      cond do
        donation.donor_pays_fees == true ->
          amount_with_fees(donation.amount)
        donation.donor_pays_fees == false ->
          donation.amount
      end

    %{
      "amount" =>  amount,
      "currency" => donation.currency,
      "source" => donation.str_src,
      "receipt_email" => donation.user.email,
      "customer" => donation.str_cus_id
    }
  end

  defp amount_with_fees(%Decimal{} = amount) do
    gateway = Decimal.mult(amount, Decimal.from_float(0.034)) |> Decimal.add(Decimal.from_float(2.35))
    bravera = Decimal.mult(amount, Decimal.from_float(0.06))

    Decimal.add(gateway, bravera) |> Decimal.add(amount)
  end

  defp truncate_exceeding_distance(%NGOChal{distance_covered: distance_covered, distance_target: distance_target}) do
    # Do not let the transaction pass target_distance.
    distance_covered = distance_covered |> Decimal.round |> Decimal.to_integer
    Enum.min([distance_covered, distance_target])
    |> Decimal.new()
  end
end
