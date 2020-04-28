defmodule OmegaBravera.Offers.OfferAppActivitiesIngestion do
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

  def start(%ActivityAccumulator{} = activity) do
    Logger.info("Offers:AppActivityIngestion: processing app activity: #{inspect(activity)}")

    activity.user_id
    |> Accounts.get_challenges_for_offers()
    |> process_challenges(activity)
  end

  def process_challenges([{_challenge_id, user} | _] = challenges, activity) do
    Logger.info("Offers:AppActivityIngestion: Processing challenges")
    Logger.info("Offers:AppActivityIngestion: Processing activity: #{inspect(activity)}")

    Enum.map(challenges, fn {challenge_id, user} ->
      challenge_id
      |> Offers.get_offer_challenge!()
      |> Repo.preload([:offer])
      |> process_challenge(activity, user, true)
    end)

    Absinthe.Subscription.publish(
      OmegaBraveraWeb.Endpoint,
      OmegaBravera.Accounts.user_live_challenges(user.id),
      live_challenges: user.id
    )
  end

  def process_challenges([], _activity) do
    Logger.info("Offers:AppActivityIngestion: No challenges found")
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
      "Offers:AppActivityIngestion: Processing #{inspect(challenge.type)} challenge: #{
        inspect(challenge.id)
      }"
    )

    {status, _challenge, _activity} =
      challenge
      |> create_activity(activity, user, send_emails)
      |> update_challenge()
      |> notify_participant_of_activity(send_emails)

    Logger.info(
      "Offers:AppActivityIngestion: Processing has finished for #{inspect(challenge.type)} challenge: #{
        inspect(challenge.id)
      }"
    )

    if status == :ok do
      Logger.info(
        "Offers:AppActivityIngestion: Processing was successful for #{inspect(challenge.type)} challenge: #{
          inspect(challenge.id)
        }"
      )

      {:ok, :challenge_updated}
    else
      Logger.info(
        "Offers:AppActivityIngestion: Processing was not successful for #{inspect(challenge.type)} challenge: #{
          inspect(challenge.id)
        }"
      )

      {:error, :activity_not_processed}
    end
  end

  def process_challenge(_, _, _, _), do: {:error, :activity_not_processed}

  def create_activity(
        %OfferChallenge{type: "BRAVERA_SEGMENT"} = challenge,
        %{strava_id: strava_id} = activity,
        _user,
        send_emails
      )
      when not is_nil(strava_id) do
    if valid_activity?(activity, challenge, send_emails) and
         OfferChallenge.has_relevant_segment(challenge, activity) do
      case Offers.create_offer_challenge_activity_m2m(activity, challenge) do
        {:ok, _activity} ->
          {:ok, challenge, activity}

        {:error, changeset} ->
          Logger.warn(
            "Offers:AppActivityIngestion: activity could not be saved. Changeset errors: #{
              inspect(changeset.errors)
            }"
          )

          {:error, challenge, nil}
      end
    else
      {:error, challenge, nil}
    end
  end

  def create_activity(%OfferChallenge{type: "PER_KM"} = challenge, activity, _user, send_emails) do
    if valid_activity?(activity, challenge, send_emails) do
      case Offers.create_offer_challenge_activity_m2m(activity, challenge) do
        {:ok, _activity} ->
          {:ok, challenge, activity}

        {:error, changeset} ->
          Logger.warn(
            "Offers:AppActivityIngestion: activity could not be saved. Changeset errors: #{
              inspect(changeset.errors)
            }"
          )

          {:error, challenge, nil}
      end
    else
      {:error, challenge, nil}
    end
  end

  def create_activity(challenge, _, _, _) do
    Logger.info(
      "Offers:AppActivityIngestion: did not process for challenge: #{inspect(challenge.id)}"
    )

    {:error, challenge, nil}
  end

  @spec update_challenge(
          {:ok, OfferChallenge.t(), Offers.OfferChallengeActivitiesM2m.t()}
          | {:error, any(), any()}
        ) ::
          {:ok, OfferChallenge.t(), Offers.OfferChallengeActivitiesM2m.t()}
          | {:error, any(), any()}
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
        Repo.get_by(OfferRedeem, offer_challenge_id: updated.id, user_id: updated.user_id)

      Offers.update_offer_redeems(offer_redeem, %{expired_at: expired_at})
    end

    {:ok, updated, activity}
  end

  defp update_challenge({:error, _, _} = params), do: params

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
            "OfferAppActivitiesIngestion: could not send reward email. I did not find OfferRedeem for team member: #{
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
          "OfferAppActivitiesIngestion: could not send reward email. I did not find OfferRedeem. for challenge owner: #{
            inspect(challenge.user)
          }"
        )
      end
    end

    params
  end

  defp notify_participant_of_activity(
         {_status, _challenge, _activity} = params,
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
