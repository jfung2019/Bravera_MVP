defmodule OmegaBravera.Challenges.KmChallengesWorker do
  require Logger

  alias OmegaBravera.{Challenges, Money.Donation, Donations.Processor}

  def start() do
    Logger.info("KM Challenges Donation collector worker starting..")

    Challenges.get_expired_km_challenges()
    |> Enum.map(fn challenge -> charge_donations(challenge.donations) end)

    Logger.info("KM Challenges Donation collector worker done!")
  end

  defp charge_donations(donations) do
    Enum.map(donations, &notify_donor_and_charge_donation/1)
  end

  defp notify_donor_and_charge_donation(donation) do
    Logger.info("Charging donation id: #{donation.id}")
    Challenges.Notifier.send_donor_milestone_email(donation)

    case Processor.charge_donation(donation) do
      {:ok, %Donation{status: "charged"} = charged_donation} ->
        Logger.info("Successfully charged #{inspect(charged_donation)}")

      {:error, reason} ->
        Logger.error(reason)
    end
  end
end
