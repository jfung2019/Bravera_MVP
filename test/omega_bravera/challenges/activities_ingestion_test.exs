defmodule OmegaBravera.Challenges.ActivitiesIngestionTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Mock
  import OmegaBravera.Factory

  alias OmegaBravera.{
    Challenges.NGOChal,
    Challenges.ActivitiesIngestion,
    Repo,
    Accounts,
    Challenges,
    Donations.Processor,
    Challenges.KmChallengesWorker,
    Money.Donation
  }

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")

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
      challenge = insert(:ngo_challenge)
      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      assert {:ok, _, _} = ActivitiesIngestion.create_activity(challenge, strava_activity)
    end

    test "returns error when activity is manual and the environment is set to accept only non-manual activities",
         %{
           strava_activity: strava_activity
         } do
      challenge = insert(:ngo_challenge)
      strava_activity = Map.put(strava_activity, :manual, true)

      assert {:error, _, _} = ActivitiesIngestion.create_activity(challenge, strava_activity)
    end

    test "returns error when activity dates are invalid", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:ngo_challenge)

      strava_activity =
        Map.put(strava_activity, :start_date, Timex.shift(Timex.now(), days: -10))
        |> Map.replace!(:type, challenge.activity_type)

      assert {:error, _, _} = ActivitiesIngestion.create_activity(challenge, strava_activity)
    end

    test "challenge not processed when activity type does not match challenge type", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:ngo_challenge)
      strava_activity = Map.replace!(strava_activity, :type, "invalid_type")

      assert {:error, _, _} = ActivitiesIngestion.create_activity(challenge, strava_activity)
    end
  end

  describe "process_challenges/2" do
    test "returns an error when no challengers are found" do
      user = insert(:user, strava: build(:strava, user: nil))
      challengers = Accounts.get_strava_challengers(user.strava.athlete_id)

      assert ActivitiesIngestion.process_challenges(challengers, user.strava.athlete_id) ==
               {:error, :no_challengers_found}
    end

    test "processes challenges if challengers were found", %{
      strava_activity: strava_activity
    } do
      user = insert(:user, strava: build(:strava, user: nil))
      ngo = insert(:ngo, %{user: user})
      challenge = insert(:ngo_challenge, %{ngo: ngo, user: user})
      donation = insert(:donation, %{ngo_chal: challenge})

      challengers = Accounts.get_strava_challengers(user.strava.athlete_id)
      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      with_mocks([
        {Strava.Activity, [], [retrieve: fn _, _, _ -> strava_activity end]},
        {Processor, [],
         [
           charge_donation: fn _ ->
             {:ok, Map.put(donation, :status, "charged")}
           end
         ]}
      ]) do
        assert ActivitiesIngestion.process_challenges(challengers, %{"object_id" => 123_456}) ==
                 [ok: :challenge_updated]

        assert called(Strava.Activity.retrieve(:_, :_, :_))
        assert called(Processor.charge_donation(:_))
      end
    end

    test "stops processing if challange is not live" do
      user = insert(:user, strava: build(:strava, user: nil))

      ngo =
        insert(
          :ngo,
          %{
            user: user,
            open_registration: false,
            pre_registration_start_date: Timex.shift(Timex.now(), days: 3)
          }
        )

      challenge =
        insert(
          :ngo_challenge,
          %{
            ngo: ngo,
            user: user,
            status: "pre_registration",
            start_date: ngo.launch_date
          }
        )

      insert(:donation, %{ngo_chal: challenge})

      challengers = Accounts.get_strava_challengers(user.strava.athlete_id)

      assert ActivitiesIngestion.process_challenges(challengers, %{"object_id" => 123_456}) ==
               {:error, :no_challengers_found}
    end

    test "processes team member activity", %{strava_activity: strava_activity} do
      challenge_owner = insert(:user, %{strava: build(:strava, user: nil)})
      team = insert(:team, user: challenge_owner, challenge: build(:ngo_challenge, %{has_team: true, user: challenge_owner}))
      team_user = insert(:user, strava: build(:strava, user: nil))
      insert(:team_member, %{user_id: team_user.id, team_id: team.id})

      donation = insert(:donation, %{ngo_chal: team.challenge, user: team_user})
      strava_activity = Map.replace!(strava_activity, :type, team.challenge.activity_type)
      challengers = Accounts.get_strava_challengers(team_user.strava.athlete_id)

      with_mocks([
        {Strava.Activity, [], [retrieve: fn _, _, _ -> strava_activity end]},
        {Processor, [],
         [
           charge_donation: fn _ ->
             {:ok, Map.put(donation, :status, "charged")}
           end
         ]}
      ]) do
        assert ActivitiesIngestion.process_challenges(challengers, %{"object_id" => 123_456}) ==
                 [ok: :challenge_updated]

        assert called(Strava.Activity.retrieve(:_, :_, :_))
        assert called(Processor.charge_donation(:_))
      end

    end
  end

  describe "process_challenge/2" do
    test "does nothing if the Strava activity distance is <= 0" do
      challenge = insert(:ngo_challenge)

      assert ActivitiesIngestion.process_challenge(challenge.id, %Strava.Activity{
               distance: 0,
               type: challenge.activity_type
             }) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity distance is <= 0 for km challenge" do
      challenge = insert(:ngo_challenge, %{type: "PER_KM"})

      assert ActivitiesIngestion.process_challenge(challenge.id, %Strava.Activity{
               distance: 0,
               type: challenge.activity_type
             }) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is before the challenge start date", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:ngo_challenge)

      strava_activity =
        Map.put(strava_activity, :start_date, Timex.shift(Timex.now(), days: -10))
        |> Map.replace!(:type, challenge.activity_type)

      assert ActivitiesIngestion.process_challenge(challenge.id, strava_activity) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is after the challenge end date", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:ngo_challenge)

      strava_activity =
        Map.put(strava_activity, :start_date, Timex.shift(Timex.now(), days: 6))
        |> Map.replace!(:type, challenge.activity_type)

      assert ActivitiesIngestion.process_challenge(challenge, strava_activity) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity is missing data" do
      challenge = insert(:ngo_challenge)

      assert ActivitiesIngestion.process_challenge(
               challenge,
               %Strava.Activity{}
             ) == {:error, :activity_not_processed}
    end

    test "updates the challenge with the new covered distance", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:ngo_challenge)
      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      {:ok, :challenge_updated} =
        ActivitiesIngestion.process_challenge(challenge, strava_activity)

      updated_challenge = Challenges.get_ngo_chal_by_slugs(challenge.ngo.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.new(1.7)
    end

    test "updates a km challenge with the new covered distance", %{
      strava_activity: strava_activity
    } do
      challenge = insert(:ngo_challenge, %{type: "PER_KM"})
      strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

      {:ok, :challenge_updated} =
        ActivitiesIngestion.process_challenge(challenge, strava_activity)

      updated_challenge = Challenges.get_ngo_chal_by_slugs(challenge.ngo.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.new(1.7)
    end

    test "updates the challenge status if the covered distance is greater than the target distance",
         %{strava_activity: strava_activity} do
      challenge = insert(:ngo_challenge, %{distance_target: 50})

      activity =
        strava_activity
        |> Map.put(:type, challenge.activity_type)
        |> Map.put(:distance, 50500)
        |> Map.put(:id, 1)

      {:ok, :challenge_updated} = ActivitiesIngestion.process_challenge(challenge, activity)

      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "updates a km challenge status if the covered distance is greater than the target distance",
         %{strava_activity: strava_activity} do
      challenge = insert(:ngo_challenge, %{distance_target: 50, type: "PER_KM"})

      activity =
        strava_activity
        |> Map.put(:type, challenge.activity_type)
        |> Map.put(:distance, 50500)
        |> Map.put(:id, 1)

      {:ok, :challenge_updated} = ActivitiesIngestion.process_challenge(challenge, activity)

      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "charges the chargeable donations", %{strava_activity: strava_activity} do
      use_cassette "process_milestone_donation" do
        user = insert(:user)
        ngo = insert(:ngo, %{slug: "swcc-1"})
        donor = insert(:user, %{email: "camonz@camonz.com"})

        challenge =
          insert(:ngo_challenge, %{
            ngo: ngo,
            user: user,
            distance_target: 150,
            distance_covered: 51
          })

        donation_params = %{
          ngo_chal: challenge,
          ngo: ngo,
          user: donor,
          milestone: 2,
          milestone_distance: 50,
          str_cus_id: "cus_DaUL9L27e843XN",
          str_src: "src_1D7qTcHjHTiyg867gAya4pe5"
        }

        insert(:donation, donation_params)
        strava_activity = Map.replace!(strava_activity, :type, challenge.activity_type)

        {:ok, :challenge_updated} =
          ActivitiesIngestion.process_challenge(challenge, strava_activity)

        challenge = Repo.get(NGOChal, challenge.id) |> Repo.preload([:activities])

        assert length(challenge.activities) == 1
      end
    end

    test "charges the chargeable donations for a km challenge", %{
      strava_activity: strava_activity
    } do
      use_cassette "process_km_donation" do
        user = insert(:user)
        ngo = insert(:ngo, %{slug: "sherief-1"})
        donor = insert(:user, %{email: "sheriefalaa.w@gmail.com"})

        challenge =
          insert(:ngo_challenge, %{
            ngo: ngo,
            user: user,
            distance_target: 150,
            type: "PER_KM"
          })

        donation_params = %{
          ngo_chal: challenge,
          ngo: ngo,
          user: donor,
          str_cus_id: "cus_DaUL9L27e843XN",
          str_src: "src_1D7qTcHjHTiyg867gAya4pe5"
        }

        donation = insert(:km_donation, donation_params)

        strava_activity =
          strava_activity
          |> Map.replace!(:type, challenge.activity_type)
          |> Map.replace!(:distance, Decimal.new(50000))

        {:ok, :challenge_updated} =
          ActivitiesIngestion.process_challenge(challenge, strava_activity)

        challenge = Challenges.get_ngo_chal!(challenge.id) |> Repo.preload(:activities)

        assert length(challenge.activities) == 1

        # Run the worker and try to charge donation == donation still pending
        KmChallengesWorker.start()
        donation = Repo.get(Donation, donation.id)

        assert donation.status == "pending"

        # End the challenge
        changeset =
          Ecto.Changeset.change(challenge, %{end_date: Timex.shift(Timex.now(), days: -10)})

        {:ok, _updated_challenge} = Repo.update(changeset)

        # Run the worker and try to charge donation == donation status is charged and charged_amount is amount * distnance_covered
        KmChallengesWorker.start()
        donation = Repo.get(Donation, donation.id)

        assert donation.status == "charged"

        assert donation.charged_amount ==
                 Decimal.mult(donation.amount, challenge.distance_covered) |> Decimal.round(1)
      end
    end
  end
end