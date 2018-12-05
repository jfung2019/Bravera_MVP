defmodule Mix.Tasks.OmegaBravera.ChargeKmChallenges do
  require Logger

  use Mix.Task

  alias OmegaBravera.Challenges
  alias OmegaBravera.Money.Donation
  alias OmegaBravera.Donations.Processor

  def run() do
    expired_challenges = Challenges.get_expired_km_challenges()

    expired_challenges
    |> Enum.map(fn challenge -> charge_donations(challenge.donations) end)
  end

  defp charge_donations(donations) do
    Enum.map(donations, &notify_donor_and_charge_donation/1)
  end

  defp notify_donor_and_charge_donation(donation) do
    Challenges.Notifier.send_donor_milestone_email(donation)

    case Processor.charge_donation(donation) do
      {:ok, %Donation{status: "charged"} = charged_donation} ->
        charged_donation

      {:error, reason} ->
        Logger.error(reason)
        nil
    end
  end
end



