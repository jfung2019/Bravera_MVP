defmodule OmegaBravera.OfferChallengesActivitiesIngestionTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import OmegaBravera.Factory

  alias OmegaBravera.Offers.{
    OfferChallenge,
    OfferActivitiesIngestion
  }

  alias OmegaBravera.Activity.ActivityAccumulator

  alias OmegaBravera.{
    Repo,
    Accounts,
    Offers
  }

  alias OmegaBravera.Activity.Activities

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")
  end

  describe "create_activity/2" do
    test "returns ok when activity is valid" do
      challenge = insert(:offer_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      assert {:ok, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "returns ok when activity is Ride (called 'Cycle' in Bravera)" do
      challenge = insert(:offer_challenge, activity_type: "Cycle")
      activity = insert(:activity_accumulator, %{type: "Ride"})

      assert {:ok, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "returns error when activity is manual and the environment is set to accept only non-manual activities" do
      challenge = insert(:offer_challenge)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type, manual: true})

      assert {:error, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "returns error when activity dates are invalid" do
      challenge = insert(:offer_challenge)

      activity =
        insert(:activity_accumulator, %{
          type: challenge.activity_type,
          start_date: Timex.shift(Timex.now(), days: -10)
        })

      assert {:error, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "challenge not processed when activity type does not match challenge type" do
      challenge = insert(:offer_challenge)
      activity = insert(:activity_accumulator, %{type: "bad_type"})

      assert {:error, _, _} =
               OfferActivitiesIngestion.create_activity(
                 challenge,
                 activity,
                 challenge.user,
                 true
               )
    end

    test "relevant segment activity will close a bravera segment challenge" do
      {:ok, start_date} =
        Timex.Parse.DateTime.Parser.parse("2019-07-08 05:48:39Z", "{ISO:Extended:Z}")

      offer =
        insert(:offer, %{
          start_date: Timex.shift(start_date, days: -2),
          end_date: Timex.shift(Timex.now(), days: 10),
          payment_amount: Decimal.new(57),
          offer_challenge_types: ["BRAVERA_SEGMENT"]
        })

      user = insert(:user)

      insert(:strava, %{
        athlete_id: 5_535_689,
        token: "dc218197b9b910a0c4e7e58f2496dd864b63fbff",
        user: nil,
        user_id: user.id
      })

      offer_challenge =
        insert(:offer_challenge, %{
          offer: nil,
          offer_id: offer.id,
          type: "BRAVERA_SEGMENT",
          user: nil,
          user_id: user.id,
          start_date: Timex.shift(start_date, days: -1),
          distance_target: 21_202_706
        })

      use_cassette "segment_activity" do
        {:ok, strava_activity} =
          Strava.Activities.get_activity_by_id(
            Strava.Client.new("dc218197b9b910a0c4e7e58f2496dd864b63fbff"),
            2_513_839_746,
            include_all_efforts: true
          )

        {:ok, activity} = Activities.create_activity(strava_activity, user)

        OmegaBravera.Offers.OfferActivitiesIngestion.start(activity, %{"owner_id" => 5_535_689})

        assert %OfferChallenge{status: "complete"} =
                 Offers.get_offer_challenge!(offer_challenge.id)
      end
    end
  end

  describe "process_challenges/2" do
    test "returns an error when no challengers are found" do
      user = insert(:user, strava: build(:strava, user: nil))
      challengers = Accounts.get_strava_challengers_for_offers(user.strava.athlete_id)

      assert OfferActivitiesIngestion.process_challenges(challengers, user.strava.athlete_id) ==
               {:error, :no_challengers_found}
    end

    test "processes challenges if challengers were found" do
      offer = insert(:offer)
      user = insert(:user, strava: build(:strava, user: nil))
      challenge = insert(:offer_challenge, %{offer: offer, user: user})

      challengers = Accounts.get_strava_challengers_for_offers(user.strava.athlete_id)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      assert OfferActivitiesIngestion.process_challenges(challengers, activity) == [
               ok: :challenge_updated
             ]
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

    test "processes team member activity" do
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

      activity =
        insert(:activity_accumulator, %{
          type: team.offer_challenge.activity_type,
          user: nil,
          user_id: team_user.id
        })

      [{challenge_id, _user, _token} | _tail] =
        challengers = Accounts.get_strava_challengers_for_offers(team_user.strava.athlete_id)

      assert OfferActivitiesIngestion.process_challenges(challengers, activity) == [
               ok: :challenge_updated
             ]

      assert [%ActivityAccumulator{user_id: ^team_member_user_id}] =
               Offers.latest_activities(%OfferChallenge{id: challenge_id}, 1)
    end
  end

  describe "process_challenge/2" do
    test "does nothing if the Strava activity distance is <= 0" do
      challenge = insert(:offer_challenge)

      assert OfferActivitiesIngestion.process_challenge(
               challenge.id,
               %ActivityAccumulator{
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
               %ActivityAccumulator{
                 distance: 0,
                 type: challenge.activity_type
               },
               challenge.user,
               true
             ) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is before the challenge start date" do
      challenge = insert(:offer_challenge)

      activity =
        insert(:activity_accumulator, %{
          type: challenge.activity_type,
          start_date: Timex.shift(Timex.now(), days: -10)
        })

      assert OfferActivitiesIngestion.process_challenge(
               challenge.id,
               activity,
               challenge.user,
               true
             ) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is after the challenge end date" do
      challenge = insert(:offer_challenge)

      activity =
        insert(:activity_accumulator, %{
          type: challenge.activity_type,
          start_date: Timex.shift(Timex.now(), days: 6)
        })

      assert OfferActivitiesIngestion.process_challenge(
               challenge,
               activity,
               challenge.user,
               true
             ) ==
               {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity is missing data" do
      challenge = insert(:offer_challenge)

      assert OfferActivitiesIngestion.process_challenge(
               challenge,
               %ActivityAccumulator{},
               challenge.user,
               true
             ) == {:error, :activity_not_processed}
    end

    test "updates the challenge with the new covered distance" do
      challenge = insert(:offer_challenge)
      Offers.create_offer_redeems(challenge, challenge.offer.vendor)
      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(
          challenge,
          activity,
          challenge.user,
          true
        )

      updated_challenge = Offers.get_offer_chal_by_slugs(challenge.offer.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.from_float(1.7)
    end

    test "updates a km challenge with the new covered distance" do
      challenge = insert(:offer_challenge, %{type: "PER_KM"})

      Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      activity = insert(:activity_accumulator, %{type: challenge.activity_type})

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(
          challenge,
          activity,
          challenge.user,
          true
        )

      updated_challenge = Offers.get_offer_chal_by_slugs(challenge.offer.slug, challenge.slug)

      assert updated_challenge.distance_covered == Decimal.from_float(1.7)
    end

    test "updates the challenge status if the covered distance is greater than the target distance" do
      challenge = insert(:offer_challenge, %{distance_target: 50})

      Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      activity =
        insert(:activity_accumulator, %{type: challenge.activity_type, distance: 50500, id: 1})

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Repo.get!(OfferChallenge, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "updates offer redeem with expired_at if offer has expiration days" do
      offer = insert(:offer, %{redemption_days: 1})

      challenge =
        insert(:offer_challenge, %{distance_target: 50, offer: offer, offer_id: offer.id})

      assert {:ok, %{id: redeem_id, status: "pending", expired_at: nil}} =
               Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      activity =
        insert(:activity_accumulator, %{type: challenge.activity_type, distance: 50500, id: 1})

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Repo.get!(OfferChallenge, challenge.id)

      assert updated_challenge.status == "complete"
      assert %{expired_at: %DateTime{}} = Offers.get_offer_redeems!(redeem_id)
    end

    test "updates a km challenge status if the covered distance is greater than the target distance" do
      challenge = insert(:offer_challenge, %{distance_target: 50, type: "PER_KM"})

      Offers.create_offer_redeems(challenge, challenge.offer.vendor)

      activity =
        insert(:activity_accumulator, %{type: challenge.activity_type, distance: 50500, id: 1})

      {:ok, :challenge_updated} =
        OfferActivitiesIngestion.process_challenge(challenge, activity, challenge.user, true)

      updated_challenge = Repo.get!(OfferChallenge, challenge.id)

      assert updated_challenge.status == "complete"
    end
  end
end
