defmodule OmegaBravera.Challenges.ActivitiesIngestion do
  require Logger

  alias OmegaBravera.{
    Accounts,
    Challenges,
    Challenges.NGOChal,
    Donations.Processor,
    Money,
    Money.Donation,
    Activity.ActivityAccumulator,
    Repo
  }

  def start(%ActivityAccumulator{} = activity, %{"owner_id" => athlete_id}) do
    Logger.info("ActivityIngestion: Strava POST webhook processing: #{inspect(activity)}")

    athlete_id
    |> Accounts.get_strava_challengers()
    |> process_challenges(activity)
  end

  def start(activity, _params),
    do: Logger.info("ActivityIngestion: not processed: #{inspect(activity)}")

  def process_challenges([{_challenge_id, _user, _token} | _] = challenges, activity) do
    Logger.info("ActivityIngestion: Processing challenges")
    Logger.info("ActivityIngestion: Processing activity: #{inspect(activity)}")

    Enum.map(challenges, fn {challenge_id, user, _token} ->
      challenge_id
      |> Challenges.get_ngo_chal!()
      |> Repo.preload([:ngo])
      |> process_challenge(activity, user, true)
    end)
  end

  def process_challenges([], _activity) do
    Logger.info("ActivityIngestion: No challengers found")
    {:error, :no_challengers_found}
  end

  def process_challenges(challenge, activity, send_emails \\ true) do
    process_challenge(challenge, activity, challenge.user, send_emails)
  end

  def process_challenge(
        %NGOChal{type: "PER_KM"} = challenge,
        %ActivityAccumulator{distance: distance} = activity,
        user,
        send_emails
      )
      when distance > 0 do
    Logger.info("ActivityIngestion: Processing km challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity, _donations} =
      challenge
      |> create_activity(activity, user, send_emails)
      |> update_challenge
      |> notify_participant_of_activity(send_emails)
      |> get_donations
      |> notify_participant_of_milestone(send_emails)

    Logger.info(
      "ActivityIngestion: Processing has finished for km challenge: #{inspect(challenge.id)}"
    )

    if status == :ok do
      Logger.info(
        "ActivityIngestion: Processing was successful for km challenge: #{inspect(challenge.id)}"
      )

      {:ok, :challenge_updated}
    else
      Logger.info(
        "ActivityIngestion: Processing was not successful for km challenge: #{inspect(challenge.id)}"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(
        %NGOChal{type: "PER_MILESTONE"} = challenge,
        %ActivityAccumulator{distance: distance} = activity,
        user,
        send_emails
      )
      when distance > 0 do
    Logger.info("ActivityIngestion: Processing milestone challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity, donations} =
      challenge
      |> create_activity(activity, user, send_emails)
      |> update_challenge()
      |> notify_participant_of_activity(send_emails)
      |> get_donations()
      |> notify_participant_of_milestone(send_emails)
      |> charge_donations(send_emails)

    Logger.info(
      "ActivityIngestion: Processing has finished for milestone challenge: #{inspect(challenge.id)}"
    )

    if status == :ok and Enum.all?(donations, &match?(%Donation{status: "charged"}, &1)) do
      Logger.info(
        "ActivityIngestion: Processing was successful for milestone challenge: #{inspect(challenge.id)}"
      )

      {:ok, :challenge_updated}
    else
      Logger.info(
        "ActivityIngestion: Processing was not successful for milestone challenge: #{inspect(challenge.id)}"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(_, _, _, _), do: {:error, :activity_not_processed}

  def create_activity(challenge, activity, _user, send_emails) do
    if valid_activity?(activity, challenge, send_emails) do
      case Challenges.create_ngo_challenge_activity_m2m(activity, challenge) do
        {:ok, _activity} ->
          {:ok, challenge, activity}

        {:error, changeset} ->
          Logger.warn(
            "ActivityIngestion: activity could not be saved. Changeset errors: #{inspect(changeset.errors)}"
          )

          {:error, challenge, nil}
      end
    else
      {:error, challenge, nil}
    end
  end

  defp update_challenge({:ok, challenge, activity}) do
    updated =
      challenge
      |> NGOChal.activity_completed_changeset(activity)
      |> Repo.update!()

    {:ok, updated, activity}
  end

  defp update_challenge({:error, _, _} = params), do: params

  defp notify_participant_of_activity({status, challenge, activity} = params, send_emails) do
    if status == :ok and send_emails do
      Challenges.Notifier.send_activity_completed_email(challenge, activity)
    end

    params
  end

  defp get_donations({:ok, challenge, _} = params),
    do: Tuple.append(params, Money.chargeable_donations_for_challenge(challenge))

  defp get_donations({:error, challenge, _} = params) do
    Logger.info("Could not get donations for challenge #{inspect(challenge.slug)}")
    Tuple.append(params, nil)
  end

  defp notify_participant_of_milestone({status, challenge, _, donations} = params, send_emails) do
    if status == :ok and length(donations) > 0 and send_emails do
      Challenges.Notifier.send_participant_milestone_email(challenge)
    end

    params
  end

  defp charge_donations({status, _, _, donations} = params, send_emails) do
    charged_donations =
      case status do
        :ok ->
          Enum.map(donations, fn donation ->
            notify_donor_and_charge_donation(donation, send_emails)
          end)

        :error ->
          []
      end

    put_elem(params, 3, charged_donations)
  end

  defp notify_donor_and_charge_donation(donation, send_emails) do
    if send_emails do
      Challenges.Notifier.send_donor_milestone_email(donation)
    end

    case Processor.charge_donation(donation) do
      {:ok, %Donation{status: "charged"} = charged_donation} ->
        charged_donation

      {:error, reason} ->
        Logger.error("Failed to charge donation, reason: #{inspect(reason)}")
        nil
    end
  end

  defp valid_activity?(activity, challenge, send_emails) do
    # challenge start date is before the activity start date and the challenge end date is after or equal to the activity start date
    challenge_started_first = Timex.compare(challenge.start_date, activity.start_date) == -1
    if !challenge_started_first, do: Logger.info("Activity before start date of challenge")
    activity_started_before_end = Timex.compare(challenge.end_date, activity.start_date) >= 0
    if !activity_started_before_end, do: Logger.info("Activity started after challenge ended")

    allow_manual_activity =
      if Application.get_env(:omega_bravera, :enable_manual_activities) == false and
           activity.manual == true do
        Logger.info("Manual activity triggered and blocked!")

        if send_emails do
          Challenges.Notifier.send_manual_activity_blocked_email(challenge)
        end

        false
      else
        true
      end

    challenge_started_first and activity_started_before_end and allow_manual_activity
  end
end
