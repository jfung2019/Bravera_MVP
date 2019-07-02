defmodule OmegaBravera.Challenges.ActivitiesIngestionTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import OmegaBravera.Factory

  alias OmegaBravera.{
    Challenges.NGOChal,
    Challenges.ActivitiesIngestion,
    Repo,
    Accounts,
    Challenges,
    Challenges.KmChallengesWorker,
    Money.Donation
  }

  alias OmegaBravera.Activity.ActivityAccumulator

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")
  end

  describe "create_activity/2" do
    test "returns ok when activity is valid" do
      challenge = insert(:ngo_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      assert {:ok, _, _} =
               ActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "returns ok when activity is Ride (called 'Cycle' in Bravera)" do
      challenge = insert(:ngo_challenge, activity_type: "Cycle")
      activity = insert(:activity_accumulator, %{type: "Ride"})

      assert {:ok, _, _} =
               ActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "returns error when activity is manual and the environment is set to accept only non-manual activities" do
      challenge = insert(:ngo_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type, manual: true})

      assert {:error, _, _} =
               ActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "returns error when activity dates are invalid" do
      challenge = insert(:ngo_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type, start_date: Timex.shift(Timex.now(), days: -10)})

      assert {:error, _, _} =
               ActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "challenge not processed when activity type does not match challenge type" do
      challenge = insert(:ngo_challenge)
      activity = insert(:activity_accumulator, %{type: "bad_type"})

      assert {:error, _, _} =
               ActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end
  end

  describe "process_challenges/2" do
    test "returns an error when no challengers are found" do
      user = insert(:user, strava: build(:strava, user: nil))
      challengers = Accounts.get_strava_challengers(user.strava.athlete_id)

      assert ActivitiesIngestion.process_challenges(challengers, user.strava.athlete_id) ==
               {:error, :no_challengers_found}
    end

    test "processes challenges if challengers were found" do
      user = insert(:user, strava: build(:strava, user: nil))
      ngo = insert(:ngo, %{user: user})
      challenge = insert(:ngo_challenge, %{ngo: ngo, user: user})

      challengers = Accounts.get_strava_challengers(user.strava.athlete_id)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      assert ActivitiesIngestion.process_challenges(challengers, activity) == [ok: :challenge_updated]
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

      assert ActivitiesIngestion.process_challenges(challengers, %{}) == {:error, :no_challengers_found}
    end

    test "processes team member activity" do
      challenge_owner = insert(:user, %{strava: build(:strava, user: nil, athlete_id: 1)})

      team =
        insert(:team,
          user: challenge_owner,
          challenge: build(:ngo_challenge, %{has_team: true, user: challenge_owner})
        )

      %{id: team_member_user_id} =
        team_user = insert(:user, strava: build(:strava, user: nil, athlete_id: 2))

      insert(:team_member, %{user_id: team_user.id, team_id: team.id})

      activity = insert(:activity_accumulator, %{type: team.challenge.activity_type, user: nil, user_id: team_user.id})

      [{challenge_id, _user, _token} | _tail] =
        challengers = Accounts.get_strava_challengers(team_user.strava.athlete_id)

      assert ActivitiesIngestion.process_challenges(challengers, activity) ==
                [ok: :challenge_updated]

      assert [%ActivityAccumulator{user_id: ^team_member_user_id}] =
                Challenges.latest_activities(%NGOChal{id: challenge_id}, 1)
    end
  end

  describe "process_challenge/2" do
    test "does nothing if the Strava activity distance is <= 0" do
      challenge = insert(:ngo_challenge)

      assert ActivitiesIngestion.process_challenge(
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
      challenge = insert(:ngo_challenge, %{type: "PER_KM"})

      assert ActivitiesIngestion.process_challenge(
               challenge.id,
               %Strava.Activity{
                 distance: 0,
                 type: challenge.activity_type
               },
               challenge.user,
               true
             ) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is before the challenge start date" do
      challenge = insert(:ngo_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type, start_date: Timex.shift(Timex.now(), days: -10)})

      assert ActivitiesIngestion.process_challenge(
               challenge.id,
               activity,
               challenge.user,
               true
             ) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is after the challenge end date" do
      challenge = insert(:ngo_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type, start_date: Timex.shift(Timex.now(), days: 6)})

      assert ActivitiesIngestion.process_challenge(
               challenge,
               activity,
               challenge.user,
               true
             ) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity is missing data" do
      challenge = insert(:ngo_challenge)

      assert ActivitiesIngestion.process_challenge(
               challenge,
               %Strava.Activity{},
               challenge.user,
               true
             ) == {:error, :activity_not_processed}
    end

    test "updates the challenge with the new covered distance" do
      challenge = insert(:ngo_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      {:ok, :challenge_updated} =
        ActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Challenges.get_ngo_chal_by_slugs(challenge.ngo.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.from_float(1.7)
    end

    test "updates a km challenge with the new covered distance" do
      challenge = insert(:ngo_challenge, %{type: "PER_KM"})
      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      {:ok, :challenge_updated} =
        ActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Challenges.get_ngo_chal_by_slugs(challenge.ngo.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.from_float(1.7)
    end

    test "updates the challenge status if the covered distance is greater than the target distance" do
      challenge = insert(:ngo_challenge, %{distance_target: 50})

      activity = insert(:activity_accumulator, %{type: challenge.activity_type, distance: 50500, id: 1})

      {:ok, :challenge_updated} =
        ActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "updates a km challenge status if the covered distance is greater than the target distance" do
      challenge = insert(:ngo_challenge, %{distance_target: 50, type: "PER_KM"})

      activity = insert(:activity_accumulator, %{type: challenge.activity_type, distance: 50500, id: 1})

      {:ok, :challenge_updated} =
        ActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "charges the chargeable donations" do
      use_cassette "process_milestone_donation" do
        user = insert(:user)
        ngo = insert(:ngo, %{slug: "swcc-1"})
        donor = insert(:donor, %{email: "camonz@camonz.com"})

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
          donor: donor,
          milestone: 2,
          milestone_distance: 50,
          str_cus_id: "cus_DaUL9L27e843XN",
          str_src: "src_1D7qTcHjHTiyg867gAya4pe5"
        }

        insert(:donation, donation_params)
        activity = insert(:activity_accumulator, %{type: challenge.activity_type})

        {:ok, :challenge_updated} =
          ActivitiesIngestion.process_challenge(challenge, activity, user, true)

        challenge = Repo.get(NGOChal, challenge.id) |> Repo.preload([:activities])

        assert length(challenge.activities) == 1
      end
    end

    test "charges the chargeable donations for a km challenge" do
      use_cassette "process_km_donation" do
        user = insert(:user)
        ngo = insert(:ngo, %{slug: "sherief-1"})
        donor = insert(:donor, %{email: "sheriefalaa.w@gmail.com"})

        challenge =
          insert(:ngo_challenge, %{
            ngo: ngo,
            user: user,
            distance_target: 150,
            type: "PER_KM"
          })

        donation_params = %{
          amount: Decimal.new(5),
          ngo_chal: challenge,
          ngo: ngo,
          donor: donor,
          str_cus_id: "cus_DaUL9L27e843XN",
          str_src: "src_1D7qTcHjHTiyg867gAya4pe5"
        }

        donation = insert(:km_donation, donation_params)
        activity = insert(:activity_accumulator, %{type: challenge.activity_type, distance: Decimal.new(100)})

        {:ok, :challenge_updated} =
          ActivitiesIngestion.process_challenge(challenge, activity, user, true)

        challenge = Challenges.get_ngo_chal!(challenge.id) |> Repo.preload(:activities)

        assert length(challenge.activities) == 1

        # Run the worker and try to charge donation == donation still pending
        KmChallengesWorker.start()
        donation = Repo.get(Donation, donation.id)

        assert donation.status == "pending"

        end_date =
          Timex.now()
          |> Timex.shift(days: -10)
          |> DateTime.truncate(:second)

        # End the challenge
        changeset = Ecto.Changeset.change(challenge, %{end_date: end_date})

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
