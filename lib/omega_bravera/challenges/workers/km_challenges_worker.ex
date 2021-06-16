defmodule OmegaBravera.Challenges.KmChallengesWorker do
  require Logger

  alias OmegaBravera.{Challenges, Money.Donation, Donations.Processor}

  def start() do
    Challenges.get_expired_km_challenges()
    |> Enum.map(fn challenge ->
      challenge_with_distance = Challenges.get_ngo_chal!(challenge.id)

      if Decimal.cmp(challenge_with_distance.distance_covered, Decimal.new(0)) === :gt do
        charge_donations(challenge.donations)
      end
    end)
  end

  defp charge_donations(donations) do
    Enum.map(donations, &notify_donor_and_charge_donation/1)
  end

  defp notify_donor_and_charge_donation(donation) do
    Logger.info("KmChallengesWorker: Charging donation id: #{donation.id}")

    case Processor.charge_donation(donation) do
      {:ok, %Donation{status: "charged"} = charged_donation} ->
        Challenges.Notifier.send_donor_milestone_email(donation)

        Logger.info(
          "KmChallengesWorker: Successfully charged km challenge. Amount: #{inspect(charged_donation.charged_amount)}"
        )

      {:error, reason} ->
        Logger.error("KmChallengesWorker: #{inspect(reason)}")
    end
  end
end
