defmodule OmegaBravera.Donations.Processor do
  alias OmegaBravera.{Fundraisers.NGO, Challenges.NGOChal, Money, Accounts.User, StripeHelpers, Money.Donation, Repo}

  def charge_donation(%Donation{} = dn) do
    donation = Repo.preload(dn, [:ngo, :ngo_chal, :user])

    case StripeHelpers.charge_stripe_customer(donation.ngo, charge_params(donation), donation.ngo_chal_id) do
      {:ok, %{body: response_body}} ->
        case Poison.decode!(response_body) do
          %{"source" => _} ->
            Money.update_donation(donation, %{status: "charged"})
            {:ok, :donation_charged}
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
