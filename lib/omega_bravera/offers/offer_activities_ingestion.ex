defmodule OmegaBravera.Offers.OfferActivitiesIngestion do
  require Logger

  alias OmegaBravera.{
    Accounts,
    Offers,
    Offers.OfferChallenge,
    Offers.Notifier,
    Offers.OfferRedeem,
    Activity.ActivityAccumulator,
    Repo
  }

  def start(%ActivityAccumulator{} = activity, %{"owner_id" => athlete_id}) do
    Logger.info("Offers:ActivityIngestion: Strava POST webhook processing: #{inspect(activity)}")

    Logger.info(
      "Offers:ActivityIngestion: Checking if athlete has devices or segment challenges..."
    )

    user = Accounts.get_user_by_athlete_id(athlete_id)

    if not is_nil(user) do
      segment_challenges_count = Accounts.get_num_of_segment_challenges_by_user_id(user.id)

      if Accounts.user_has_device?(user.id) do
        Logger.info(
          "Offers:ActivityIngestion: User has a device and segment challenge of count #{
            segment_challenges_count
          }"
        )

        if segment_challenges_count > 0 do
          OmegaBravera.Offers.OfferAppActivitiesIngestion.start(activity)
        else
          Logger.info(
            "Offers:ActivityIngestion: User has a device, but 0 segment challenges, terminating."
          )
        end
      else
        # User has no devices
        athlete_id
        |> Accounts.get_strava_challengers_for_offers()
        |> process_challenges(activity)
      end
    end
  end

  def start(activity, _params),
    do: Logger.info("Offers:ActivityIngestion: not processed: #{inspect(activity)}")

  def process_challenges([{_challenge_id, _user, _token} | _] = challenges, activity) do
    Logger.info("Offers:ActivityIngestion: Processing challenges")
    Logger.info("Offers:ActivityIngestion: Processing activity: #{inspect(activity)}")

    Enum.map(challenges, fn {challenge_id, user, _token} ->
      challenge_id
      |> Offers.get_offer_challenge!()
      |> Repo.preload([:offer])
      |> process_challenge(activity, user, true)
    end)
  end

  def process_challenges([], _activity) do
    Logger.info("Offers:ActivityIngestion: No challengers found")
    {:error, :no_challengers_found}
  end

  def process_challenges(challenge, activity, send_emails \\ true) do
    process_challenge(challenge, activity, challenge.user, send_emails)
  end

  def process_challenge(
        %OfferChallenge{} = challenge,
        %ActivityAccumulator{distance: distance} = activity,
        user,
        send_emails
      )
      when distance > 0 do
    Logger.info(
      "Offers:ActivityIngestion: Processing #{inspect(challenge.type)} challenge: #{
        inspect(challenge.id)
      }"
    )

    {status, _challenge, _activity} =
      challenge
      |> create_activity(activity, user, send_emails)
      |> update_challenge()
      |> notify_participant_of_activity(send_emails)

    Logger.info(
      "Offers:ActivityIngestion: Processing has finished for #{inspect(challenge.type)} challenge: #{
        inspect(challenge.id)
      }"
    )

    if status == :ok do
      Logger.info(
        "Offers:ActivityIngestion: Processing was successful for #{inspect(challenge.type)} challenge: #{
          inspect(challenge.id)
        }"
      )

      {:ok, :challenge_updated}
    else
      Logger.info(
        "Offers:ActivityIngestion: Processing was not successful for #{inspect(challenge.type)} challenge: #{
          inspect(challenge.id)
        }"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(_, _, _, _), do: {:error, :activity_not_processed}

  def create_activity(
        %OfferChallenge{type: "BRAVERA_SEGMENT"} = challenge,
        activity,
        _user,
        send_emails
      ) do
    if valid_activity?(activity, challenge, send_emails) and
         OfferChallenge.has_relevant_segment(challenge, activity) do
      case Offers.create_offer_challenge_activity_m2m(activity, challenge) do
        {:ok, _activity} ->
          {:ok, challenge, activity}

        {:error, changeset} ->
          Logger.warn(
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

  def create_activity(challenge, activity, _user, send_emails) do
    if valid_activity?(activity, challenge, send_emails) do
      case Offers.create_offer_challenge_activity_m2m(activity, challenge) do
        {:ok, _activity} ->
          {:ok, challenge, activity}

        {:error, changeset} ->
          Logger.warn(
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
      |> Repo.preload([:offer])

    # if challenge was completed and offer has expiration_days
    # update the reward to the right time
    if updated.status == "complete" and updated.offer.redemption_days != nil do
      expired_at = Timex.now() |> Timex.shift(days: updated.offer.redemption_days)

      offer_redeem =
        Repo.get_by(OfferRedeem, offer_challenge_id: challenge.id, user_id: challenge.user_id)

      Offers.update_offer_redeems(offer_redeem, %{expired_at: expired_at})
    end

    {:ok, updated, activity}
  end

  defp update_challenge({:error, _, _} = params), do: params

  defp notify_participant_of_activity(
         {status, %OfferChallenge{status: "active", has_team: false} = challenge, activity} =
           params,
         send_emails
       ) do
    if status == :ok and send_emails do
      Notifier.send_activity_completed_email(challenge, activity)
    end

    params
  end

  defp notify_participant_of_activity(
         {status, %OfferChallenge{status: "active", has_team: true} = challenge, activity} =
           params,
         send_emails
       ) do
    challenge = Repo.preload(challenge, [:user, team: [:users]])
    team_members = [challenge.user] ++ challenge.team.users

    if status == :ok and send_emails do
      Enum.map(
        team_members,
        &Notifier.send_team_activity_completed_email(challenge, activity, &1)
      )
    end

    params
  end

  defp notify_participant_of_activity(
         {status, %OfferChallenge{status: "complete", has_team: true} = challenge, _activity} =
           params,
         send_emails
       ) do
    challenge = Repo.preload(challenge, [:user, team: [:users]])
    team_members = [challenge.user] ++ challenge.team.users

    if status == :ok and send_emails do
      Enum.map(team_members, fn tm ->
        offer_redeem = Repo.get_by(OfferRedeem, offer_challenge_id: challenge.id, user_id: tm.id)

        if Notifier.send_reward_completion_email(challenge, tm, offer_redeem) != :ok do
          Logger.error(
            "OfferActivitiesIngestion: could not send reward email. I did not find OfferRedeem for team member: #{
              inspect(tm)
            }"
          )
        end
      end)
    end

    params
  end

  defp notify_participant_of_activity(
         {status, %OfferChallenge{status: "complete", has_team: false} = challenge, _activity} =
           params,
         send_emails
       ) do
    if status == :ok and send_emails do
      offer_redeem =
        Repo.get_by(OfferRedeem, offer_challenge_id: challenge.id, user_id: challenge.user_id)

      challenge = Repo.preload(challenge, :user)

      if Notifier.send_reward_completion_email(challenge, challenge.user, offer_redeem) != :ok do
        Logger.error(
          "OfferActivitiesIngestion: could not send reward email. I did not find OfferRedeem. for challenge owner: #{
            inspect(challenge.user)
          }"
        )
      end
    end

    params
  end

  defp notify_participant_of_activity(
         {_status, %OfferChallenge{status: "pre_registration"}, _activity} = params,
         _
       ),
       do: params

  defp notify_participant_of_activity(
         {_status, %OfferChallenge{status: "expired"}, _activity} = params,
         _
       ),
       do: params

  defp valid_activity?(activity, challenge, _send_emails) do
    # challenge start date is before the activity start date and the challenge end date is after or equal to the activity start date
    challenge_started_first = Timex.compare(challenge.start_date, activity.start_date) == -1
    if !challenge_started_first, do: Logger.info("Activity before start date of challenge")
    activity_started_before_end = Timex.compare(challenge.end_date, activity.start_date) >= 0
    if !activity_started_before_end, do: Logger.info("Activity started after challenge ended")

    allow_manual_activity =
      if Application.get_env(:omega_bravera, :enable_manual_activities) == false and
           activity.manual == true do
        Logger.info("Manual activity triggered and blocked!")

        # if send_emails do
        #   Challenges.Notifier.send_manual_activity_blocked_email(
        #     challenge,
        #     Routes.ngo_ngo_chal_path(Endpoint, :show, challenge.ngo.slug, challenge.slug)
        #   )
        # end

        false
      else
        true
      end

    challenge_started_first and activity_started_before_end and allow_manual_activity
  end
end
