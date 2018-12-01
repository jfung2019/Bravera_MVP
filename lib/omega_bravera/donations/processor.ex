defmodule OmegaBravera.Donations.Processor do
  alias OmegaBravera.{
    Money,
    Accounts.User,
    StripeHelpers,
    Money.Donation,
    Repo,
    Donations.Notifier
  }

  def charge_donation(%Donation{} = dn) do
    donation = Repo.preload(dn, [:ngo, :ngo_chal, :user])

    case StripeHelpers.charge_stripe_customer(
           donation.ngo,
           charge_params(donation),
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

  def charge_params(%Donation{} = donation) do
    %{
      "amount" => donation.amount,
      "currency" => donation.currency,
      "source" => donation.str_src,
      "receipt_email" => donation.user.email,
      "customer" => donation.str_cus_id
    }
  end
end
