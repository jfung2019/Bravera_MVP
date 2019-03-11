defmodule OmegaBravera.Offers.OfferActivitiesIngestion do
  require Logger

  alias OmegaBravera.{
    Accounts,
    Offers,
    Offers.OfferChallenge,
    Offers.OfferChallengeActivity,
    Repo
  }

  # alias OmegaBraveraWeb.Router.Helpers, as: Routes
  # alias OmegaBraveraWeb.Endpoint

  def start(
        %{"aspect_type" => "create", "object_type" => "activity", "owner_id" => owner_id} = params
      ) do
    Logger.info("Offers:ActivityIngestion: Strava POST webhook processing: #{inspect(params)}")

    owner_id
    |> Accounts.get_strava_challengers_for_offers()
    |> process_challenges(params)
  end

  def process_strava_webhook(_), do: {:error, :webhook_not_processed}

  def process_challenges([{_challenge_id, _user, token} | _] = challenges, %{
        "object_id" => object_id
      }) do
    Logger.info("Offers:ActivityIngestion: Processing challenges")
    activity = Strava.Activity.retrieve(object_id, %{}, strava_client(token))
    Logger.info("Offers:ActivityIngestion: Processing activity: #{inspect(activity)}")

    Enum.map(challenges, fn {challenge_id, user, _token} ->
      challenge_id
      |> Offers.get_offer_challenge!()
      |> Repo.preload([:offer])
      |> process_challenge(activity, user, true)
    end)
  end

  def process_challenges([], _) do
    Logger.info("Offers:ActivityIngestion: No challengers found")
    {:error, :no_challengers_found}
  end

  def process_challenges(challenge, activity, send_emails \\ true) do
    process_challenge(challenge, activity, challenge.user, send_emails)
  end

  def process_challenge(
        %OfferChallenge{type: "PER_KM"} = challenge,
        %Strava.Activity{distance: distance} = strava_activity,
        user,
        send_emails
      )
      when distance > 0 do
    Logger.info("Offers:ActivityIngestion: Processing km challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity} =
      challenge
      |> create_activity(strava_activity, user, send_emails)
      |> update_challenge
      |> notify_participant_of_activity(send_emails)
      |> notify_participant_of_milestone(send_emails)

    Logger.info(
      "Offers:ActivityIngestion: Processing has finished for km challenge: #{inspect(challenge.id)}"
    )

    if status == :ok do
      Logger.info(
        "Offers:ActivityIngestion: Processing was successful for km challenge: #{inspect(challenge.id)}"
      )

      {:ok, :challenge_updated}
    else
      Logger.info(
        "Offers:ActivityIngestion: Processing was not successful for km challenge: #{
          inspect(challenge.id)
        }"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(
        %OfferChallenge{type: "PER_MILESTONE"} = challenge,
        %Strava.Activity{distance: distance} = strava_activity,
        user,
        send_emails
      )
      when distance > 0 do
    Logger.info("Offers:ActivityIngestion: Processing milestone challenge: #{inspect(challenge.id)}")

    {status, _challenge, _activity} =
      challenge
      |> create_activity(strava_activity, user, send_emails)
      |> update_challenge()
      |> notify_participant_of_activity(send_emails)
      |> notify_participant_of_milestone(send_emails)

    Logger.info(
      "Offers:ActivityIngestion: Processing has finished for milestone challenge: #{
        inspect(challenge.id)
      }"
    )

    if status == :ok do
      Logger.info(
        "Offers:ActivityIngestion: Processing was successful for milestone challenge: #{
          inspect(challenge.id)
        }"
      )

      {:ok, :challenge_updated}
    else
      Logger.info(
        "Offers:ActivityIngestion: Processing was not successful for milestone challenge: #{
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
          OfferChallengeActivity.create_changeset(activity, challenge, user)

        true ->
          OfferChallengeActivity.create_activity_by_admin_changeset(
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
            "Offers:ActivityIngestion: activity could not be saved. Changeset errors: #{
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
      |> OfferChallenge.activity_completed_changeset(activity)
      |> Repo.update!()

    {:ok, updated, activity}
  end

  defp update_challenge({:error, _, _} = params), do: params

  defp notify_participant_of_activity({status, _challenge, _activity} = params, send_emails) do
    if status == :ok and send_emails do
      # Challenges.Notifier.send_activity_completed_email(challenge, activity)
    end

    params
  end

  defp notify_participant_of_milestone({status, _challenge, _} = params, send_emails) do
    if status == :ok and send_emails do
      # Challenges.Notifier.send_participant_milestone_email(challenge)
    end

    params
  end

  defp strava_client(token), do: Strava.Client.new(token)

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
          # Challenges.Notifier.send_manual_activity_blocked_email(
          #   challenge,
          #   Routes.ngo_ngo_chal_path(Endpoint, :show, challenge.ngo.slug, challenge.slug)
          # )
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
