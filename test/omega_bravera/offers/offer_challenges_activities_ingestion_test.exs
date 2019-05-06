defmodule OmegaBravera.OfferChallengesActivitiesIngestionTest do
  use OmegaBravera.DataCase

  import Mock
  import OmegaBravera.Factory

  alias OmegaBravera.Offers.{
    OfferChallenge,
    OfferActivitiesIngestion,
    OfferChallengeActivity
  }

  alias OmegaBravera.{
    Repo,
    Accounts,
    Offers
  }

  setup do
    strava_activity = %Strava.Activity{
      id: 1_836_709_368,
      distance: 1740.0,
      # putting it 1h into the future so its within the duration of our factory created challenges
      start_date: Timex.shift(Timex.now(), hours: 1),
      type: "Run",
      name: "Morning Run",
      manual: false,
      moving_time: 2123,
      elapsed_time: 1233,
      average_speed: 123,
      calories: 300
    }

    {:ok, [strava_activity: strava_activity]}
  end

  describe "create_activity/2" do
    test "returns ok when activity is valid", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:offer_challenge)
      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      assert {:ok, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 strava_activity,
                 challenge.user,
                 true
               )
    end

    test "returns error when activity is manual and the environment is set to accept only non-manual activities",
         %{
           strava_activity: strava_activity
         } do
      challenge = insert(:offer_challenge)
      strava_activity = Map.put(strava_activity, :manual, true)

      assert {:error, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 strava_activity,
                 challenge.user,
                 true
               )
    end

    test "returns error when activity dates are invalid", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:offer_challenge)

      strava_activity =
        Map.put(strava_activity, :start_date, Timex.shift(Timex.now(), days: -10))
        |> Map.replace!(:type, challenge.activity_type)

      assert {:error, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 strava_activity,
                 challenge.user,
                 true
               )
    end

    test "challenge not processed when activity type does not match challenge type", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:offer_challenge)
      strava_activity = Map.replace!(strava_activity, :type, "invalid_type")

      assert {:error, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 strava_activity,
                 challenge.user,
                 true
               )
    end
  end

  describe "process_challenges/2" do
    test "returns an error when no challengers are found" do
      user = insert(:user, strava: build(:strava, user: nil))
      challengers = Accounts.get_strava_challengers_for_offers(user.strava.athlete_id)

      assert OfferActivitiesIngestion.process_challenges(challengers, user.strava.athlete_id) ==
               {:error, :no_challengers_found}
    end

    test "processes challenges if challengers were found", %{
      strava_activity: strava_activity
    } do
      offer = insert(:offer)
      user = insert(:user, strava: build(:strava, user: nil))
      challenge = insert(:offer_challenge, %{offer: offer, user: user})

      challengers = Accounts.get_strava_challengers_for_offers(user.strava.athlete_id)
      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      with_mocks([{Strava.Activity, [], [retrieve: fn _, _, _ -> strava_activity end]}]) do
        assert OfferActivitiesIngestion.process_challenges(challengers, %{"object_id" => 123_456}) ==
                 [ok: :challenge_updated]

        assert called(Strava.Activity.retrieve(:_, :_, :_))
      end
    end

    test "stops processing if challange is not live" do
      user = insert(:user, strava: build(:strava, user: nil))

      offer =
        insert(
          :offer,
          %{
            open_registration: false,
            pre_registration_start_date: Timex.shift(Timex.now(), days: 3),
            start_date: Timex.shift(Timex.now(), days: 10),
            end_date: Timex.shift(Timex.now(), days: 20)
          }
        )

      offer_challenge =
        insert(
          :offer_challenge,
          %{
            offer: offer,
            user: user,
            status: "pre_registration",
            start_date: offer.start_date,
            end_date: offer.end_date
          }
        )

      Offers.create_offer_redeems(offer_challenge, offer.vendor)

      challengers = Accounts.get_strava_challengers_for_offers(user.strava.athlete_id)

      assert OfferActivitiesIngestion.process_challenges(challengers, %{"object_id" => 123_456}) ==
               {:error, :no_challengers_found}
    end

    test "processes team member activity", %{strava_activity: strava_activity} do
      challenge_owner = insert(:user, %{strava: build(:strava, user: nil, athlete_id: 1)})

      team =
        insert(:offer_challenge_team,
          user: challenge_owner,
          offer_challenge: build(:offer_challenge, %{has_team: true, user: challenge_owner})
        )

      %{id: team_member_user_id} =
        team_user = insert(:user, strava: build(:strava, user: nil, athlete_id: 2))

      insert(:offer_challenge_team_member, %{user_id: team_user.id, team_id: team.id})

      Offers.create_offer_redeems(team.offer_challenge, team.offer_challenge.offer.vendor)

      Offers.create_offer_redeems(
        team.offer_challenge,
        team.offer_challenge.offer.vendor,
        %{},
        team_user
      )

      strava_activity = Map.replace!(strava_activity, :type, team.offer_challenge.activity_type)

      [{challenge_id, _user, _token} | _tail] =
        challengers = Accounts.get_strava_challengers_for_offers(team_user.strava.athlete_id)

      with_mocks([{Strava.Activity, [], [retrieve: fn _, _, _ -> strava_activity end]}]) do
        assert OfferActivitiesIngestion.process_challenges(challengers, %{"object_id" => 123_456}) ==
                 [ok: :challenge_updated]

        assert called(Strava.Activity.retrieve(:_, :_, :_))

        assert [%OfferChallengeActivity{user_id: ^team_member_user_id}] =
                 Offers.latest_activities(%OfferChallenge{id: challenge_id}, 1)
      end
    end
  end

  describe "process_challenge/2" do
    test "does nothing if the Strava activity distance is <= 0" do
      challenge = insert(:offer_challenge)

      assert OfferActivitiesIngestion.process_challenge(
               challenge.id,
               %Strava.Activity{
                 distance: 0,
                 type: challenge.activity_type
               },
               challenge.user,
               true
             ) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity distance is <= 0 for km challenge" do
      challenge = insert(:offer_challenge, %{type: "PER_KM"})

      assert OfferActivitiesIngestion.process_challenge(
               challenge.id,
               %Strava.Activity{
                 distance: 0,
                 type: challenge.activity_type
               },
               challenge.user,
               true
             ) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is before the challenge start date", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:offer_challenge)

      strava_activity =
        Map.put(strava_activity, :start_date, Timex.shift(Timex.now(), days: -10))
        |> Map.replace!(:type, challenge.activity_type)

      assert OfferActivitiesIngestion.process_challenge(
               challenge.id,
               strava_activity,
               challenge.user,
               true
             ) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is after the challenge end date", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:offer_challenge)

      strava_activity =
        Map.put(strava_activity, :start_date, Timex.shift(Timex.now(), days: 6))
        |> Map.replace!(:type, challenge.activity_type)

      assert OfferActivitiesIngestion.process_challenge(
               challenge,
               strava_activity,
               challenge.user,
               true
             ) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity is missing data" do
      challenge = insert(:offer_challenge)

      assert OfferActivitiesIngestion.process_challenge(
               challenge,
               %Strava.Activity{},
               challenge.user,
               true
             ) == {:error, :activity_not_processed}
    end

    test "updates the challenge with the new covered distance", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:offer_challenge)

      Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(
          challenge,
          strava_activity,
          challenge.user,
          true
        )

      updated_challenge = Offers.get_offer_chal_by_slugs(challenge.offer.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.from_float(1.7)
    end

    test "updates a km challenge with the new covered distance", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:offer_challenge, %{type: "PER_KM"})

      Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(
          challenge,
          strava_activity,
          challenge.user,
          true
        )

      updated_challenge = Offers.get_offer_chal_by_slugs(challenge.offer.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.from_float(1.7)
    end

    test "updates the challenge status if the covered distance is greater than the target distance",
         %{strava_activity: strava_activity} do
      challenge = insert(:offer_challenge, %{distance_target: 50})

      Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      activity =
        strava_activity
        |> Map.put(:type, challenge.activity_type)
        |> Map.put(:distance, 50500)
        |> Map.put(:id, 1)

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Repo.get!(OfferChallenge, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "updates a km challenge status if the covered distance is greater than the target distance",
         %{strava_activity: strava_activity} do
      challenge = insert(:offer_challenge, %{distance_target: 50, type: "PER_KM"})

      Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      activity =
        strava_activity
        |> Map.put(:type, challenge.activity_type)
        |> Map.put(:distance, 50500)
        |> Map.put(:id, 1)

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Repo.get!(OfferChallenge, challenge.id)

      assert updated_challenge.status == "complete"
    end
  end
end
