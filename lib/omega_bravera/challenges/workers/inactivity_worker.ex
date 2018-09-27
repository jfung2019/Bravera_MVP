defmodule OmegaBravera.Challenges.InactivityWorker do
  alias OmegaBravera.{Challenges, Challenges.NGOChal, Challenges.Notifier, Accounts, Repo}

  def process_inactive_challenges() do
    Challenges.inactive_for_five_days()
    |> Enum.each(&process_inactivity_for_participant/1)

    Challenges.inactive_for_seven_days()
    |> Enum.each(&process_inactivity_for_donor/1)

    :ok
  end

  defp process_inactivity_for_participant(%NGOChal{} = challenge) do
    challenge
    |> NGOChal.participant_inactivity_notification_changeset()
    |> Repo.update()

    Notifier.send_participant_inactivity_email(challenge)
  end

  defp process_inactivity_for_donor(%NGOChal{} = challenge) do
    challenge
    |> NGOChal.donor_inactivity_notification_changeset()
    |> Repo.update()

    challenge
    |> Accounts.donors_for_challenge()
    |> Enum.each(&Notifier.send_donor_inactivity_email(challenge, &1))
  end
end
