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

  alias OmegaBraveraWeb.Router.Helpers, as: Routes
  alias OmegaBraveraWeb.Endpoint

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

    Enum.map(challenges, fn {challenge_id, user} ->
      challenge_id
      |> Challenges.get_ngo_chal!()
      |> Repo.preload([:ngo])
      |> process_challenge(activity, user, true)
    end)
  end

  def process_challenges([], _) do
    Logger.info("ActivityIngestion: No challengers found")
    {:error, :no_challengers_found}
  end

  def process_challenges(challenge, activity, send_emails \\ true) do
    process_challenge(challenge, activity, challenge.user, send_emails)
  end

  def process_challenge(
        %NGOChal{type: "PER_KM"} = challenge,
        %Strava.Activity{distance: distance} = strava_activity,
        user,
        send_emails
      )
      when distance > 0 do
    Logger.info("ActivityIngestion: Processing km challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity, _donations} =
      challenge
      |> create_activity(strava_activity, user, send_emails)
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
        "ActivityIngestion: Processing was not successful for km challenge: #{
          inspect(challenge.id)
        }"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(
        %NGOChal{type: "PER_MILESTONE"} = challenge,
        %Strava.Activity{distance: distance} = strava_activity,
        user,
        send_emails
      )
      when distance > 0 do
    Logger.info("ActivityIngestion: Processing milestone challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity, donations} =
      challenge
      |> create_activity(strava_activity, user, send_emails)
      |> update_challenge()
      |> notify_participant_of_activity(send_emails)
      |> get_donations()
      |> notify_participant_of_milestone(send_emails)
      |> charge_donations(send_emails)

    Logger.info(
      "ActivityIngestion: Processing has finished for milestone challenge: #{
        inspect(challenge.id)
      }"
    )

    if status == :ok and Enum.all?(donations, &match?(%Donation{status: "charged"}, &1)) do
      Logger.info(
        "ActivityIngestion: Processing was successful for milestone challenge: #{
          inspect(challenge.id)
        }"
      )

      {:ok, :challenge_updated}
    else
      Logger.info(
        "ActivityIngestion: Processing was not successful for milestone challenge: #{
          inspect(challenge.id)
        }"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(_, _, _, _), do: {:error, :activity_not_processed}

  def create_activity(challenge, activity, user, send_emails) do
    # Check if the strava activity is an admin created one.
    changeset =
      case Map.has_key?(activity, :admin_id) do
        false ->
          Challenges.Activity.create_changeset(activity, challenge, user)

        true ->
          Challenges.Activity.create_activity_by_admin_changeset(
            activity,
            challenge,
            user,
            activity.admin_id
          )
      end

    if valid_activity?(activity, challenge, send_emails) and
         activity_type_matches_challenge_activity_type?(activity, challenge) do
      case Repo.insert(changeset) do
        {:ok, activity} ->
          {:ok, challenge, activity}

        {:error, changeset} ->
          Logger.error(
            "ActivityIngestion: activity could not be saved. Changeset errors: #{
              inspect(changeset.errors)
            }"
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
    Logger.error("Could not get donations for challenge #{inspect(challenge.slug)}")
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

  defp strava_client({_, token}), do: Strava.Client.new(token)

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
          Challenges.Notifier.send_manual_activity_blocked_email(
            challenge,
            Routes.ngo_ngo_chal_path(Endpoint, :show, challenge.ngo.slug, challenge.slug)
          )
        end

        false
      else
        true
      end

    challenge_started_first and activity_started_before_end and allow_manual_activity
  end

  defp activity_type_matches_challenge_activity_type?(%{type: activity_type}, %{
         activity_type: challenge_activity_type
       }) do
    equal? = activity_type == challenge_activity_type

    if !equal? do
      Logger.info(
        "Challenge activity type: #{challenge_activity_type} is not same as Activity type: #{
          activity_type
        }"
      )
    end

    equal?
  end
end
