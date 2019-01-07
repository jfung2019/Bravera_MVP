defmodule OmegaBravera.Challenges.ActivitiesIngestion do
  require Logger

  alias OmegaBravera.{
    Accounts,
    Challenges,
    Challenges.NGOChal,
    Donations.Processor,
    Money,
    Money.Donation,
    Repo
  }

  def process_strava_webhook(
        %{"aspect_type" => "create", "object_type" => "activity", "owner_id" => owner_id} = params
      ) do
    Logger.info("ActivityIngestion: Strava POST webhook processing: #{inspect(params)}")

    owner_id
    |> Accounts.get_strava_challengers()
    |> process_challenges(params)
  end

  def process_strava_webhook(_), do: {:error, :webhook_not_processed}

  def process_challenges([hd | _] = challenges, %{"object_id" => object_id}) do
    Logger.info("ActivityIngestion: Processing challenges")
    activity = Strava.Activity.retrieve(object_id, %{}, strava_client(hd))
    Logger.info("ActivityIngestion: Processing activity: #{inspect(activity)}")

    Enum.map(challenges, fn {challenge_id, _} ->
      challenge_id
      |> Challenges.get_ngo_chal!()
      |> Repo.preload([:user, :ngo])
      |> process_challenge(activity)
    end)
  end

  def process_challenges([], _) do
    Logger.info("ActivityIngestion: No challengers found")
    {:error, :no_challengers_found}
  end

  def process_challenge(
        %NGOChal{type: "PER_KM"} = challenge,
        %Strava.Activity{distance: distance} = strava_activity
      )
      when distance > 0 do
    Logger.info("ActivityIngestion: Processing km challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity, _donations} =
      challenge
      |> create_activity(strava_activity)
      |> update_challenge
      |> notify_participant_of_activity
      |> get_donations
      |> notify_participant_of_milestone

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
        "ActivityIngestion: Processing was not successful for km challenge: #{
          inspect(challenge.id)
        }"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(
        %NGOChal{type: "PER_MILESTONE"} = challenge,
        %Strava.Activity{distance: distance} = strava_activity
      )
      when distance > 0 do

    Logger.info("ActivityIngestion: Processing milestone challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity, donations} =
      challenge
      |> create_activity(strava_activity)
      |> update_challenge
      |> notify_participant_of_activity
      |> get_donations
      |> notify_participant_of_milestone
      |> charge_donations()

    Logger.info(
      "ActivityIngestion: Processing has finished for milestone challenge: #{
        inspect(challenge.id)
      }"
    )

    if status == :ok and Enum.all?(donations, &match?(%Donation{status: "charged"}, &1)) do
      Logger.info("ActivityIngestion: Processing was successful for milestone challenge: #{inspect(challenge.id)}")

      {:ok, :challenge_updated}
    else
      Logger.info("ActivityIngestion: Processing was not successful for milestone challenge: #{inspect(challenge.id)}")

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(_, _), do: {:error, :activity_not_processed}

  def create_activity(challenge, activity) do
    # Check if the strava activity is an admin created one.
    changeset =
      case Map.has_key?(activity, :admin_id) do
        false ->
          Challenges.Activity.create_changeset(activity, challenge)
        true ->
          Challenges.Activity.create_activity_by_admin_changeset(
            activity,
            challenge,
            activity.admin_id
          )
      end

    if valid_activity?(activity, challenge) and
         activity_type_matches_challenge_activity_type?(activity, challenge) do
      case Repo.insert(changeset) do
        {:ok, activity} -> {:ok, challenge, activity}
        {:error, _changeset} -> {:error, challenge, nil}
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

  defp notify_participant_of_activity({status, challenge, activity} = params) do
    if status == :ok do
      Challenges.Notifier.send_activity_completed_email(challenge, activity)
    end

    params
  end

  defp get_donations({:ok, challenge, _} = params),
    do: Tuple.append(params, Money.chargeable_donations_for_challenge(challenge))

  defp get_donations({:error, _, _} = params), do: Tuple.append(params, nil)

  defp notify_participant_of_milestone({status, challenge, _, donations} = params) do
    if status == :ok and length(donations) > 0 do
      Challenges.Notifier.send_participant_milestone_email(challenge)
    end

    params
  end

  defp charge_donations({status, _, _, donations} = params) do
    charged_donations =
      case status do
        :ok -> Enum.map(donations, &notify_donor_and_charge_donation/1)
        :error -> []
      end

    put_elem(params, 3, charged_donations)
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

  defp strava_client({_, token}), do: Strava.Client.new(token)

  defp valid_activity?(activity, challenge) do
    # challenge start date is before the activity start date and the challenge end date is after or equal to the activity start date
    challenge_started_first = Timex.compare(challenge.start_date, activity.start_date) == -1
    if !challenge_started_first, do: Logger.info("Activity before start date of challenge")
    activity_started_before_end = Timex.compare(challenge.end_date, activity.start_date) >= 0
    if !activity_started_before_end, do: Logger.info("Activity started after challenge ended")
    allow_manual_activity =
      if Application.get_env(:omega_bravera, :enable_manual_activities) == false  and activity.manual == true do
        Logger.info("Manual activity triggered and blocked!")
        Challenges.Notifier.send_manual_activity_blocked_email(challenge)
        false
      else
        true
      end

    challenge_started_first and activity_started_before_end and allow_manual_activity
  end

  defp activity_type_matches_challenge_activity_type?(%{type: activity_type}, %{
         activity_type: activity_type
       }),
       do: true

  defp activity_type_matches_challenge_activity_type?(%{type: activity_type}, %{
         activity_type: challenge_activity_type
       }) do
    Logger.info(
      "Challenge activity type: #{challenge_activity_type} is not same as Activity type: #{
        activity_type
      }"
    )

    false
  end
end
