defmodule OmegaBravera.Challenges.ActivitiesIngestionTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import OmegaBravera.Factory

  alias OmegaBravera.{Challenges.NGOChal, Challenges.ActivitiesIngestion, Repo}

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")

    strava_activity = %Strava.Activity{
      id: 1836709368,
      distance: 1740.0,
      start_date: Timex.shift(Timex.now, hours: 1), # putting it 1h into the future so its within the duration of our factory created challenges
      type: "Walk",
      name: "Morning Walk",
      manual: false
    }

    {:ok, [strava_activity: strava_activity]}
  end

  describe "process_challenge/2" do
    test "does nothing if the Strava activity distance is <= 0" do
      challenge = insert(:ngo_challenge)
      assert ActivitiesIngestion.process_challenge({challenge.id, nil}, %Strava.Activity{distance: 0}) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is before the challenge start date", %{strava_activity: strava_activity} do
      challenge = insert(:ngo_challenge)
      activity = Map.put(strava_activity, :start_date, Timex.shift(Timex.now, days: -10))

      assert ActivitiesIngestion.process_challenge({challenge.id, nil}, activity) == {:error, :activity_not_processed}
    end

    test "does nothing if the Strava activity start date is after the challenge end date", %{strava_activity: strava_activity} do
      challenge = insert(:ngo_challenge)
      activity = Map.put(strava_activity, :start_date, Timex.shift(Timex.now, days: 6))

      assert ActivitiesIngestion.process_challenge({challenge.id, nil}, activity) == {:error, :activity_not_processed}
    end


    test "does nothing if the Strava activity is missing data" do
      challenge = insert(:ngo_challenge)
      assert ActivitiesIngestion.process_challenge({challenge.id, nil}, %Strava.Activity{distance: 100}) == {:error, :activity_not_processed}
    end

    test "updates the challenge with the new covered distance", %{strava_activity: strava_activity} do
      challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(3.2)})

      {:ok, :challenge_updated} = ActivitiesIngestion.process_challenge({challenge.id, nil}, strava_activity)
      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.distance_covered == Decimal.new(4.94)
    end

    test "updates the challenge status if the covered distance is greater than the target distance", %{strava_activity: strava_activity} do
      challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(49.5), distance_target: 50})

      {:ok, :challenge_updated} = ActivitiesIngestion.process_challenge({challenge.id, nil}, strava_activity)
      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "charges the chargeable donations", %{strava_activity: strava_activity} do
      use_cassette "process_milestone_donation" do
        user = insert(:user)
        ngo = insert(:ngo, %{slug: "swcc-1", stripe_id: "acct_1D7jlPINRN0GH189"})
        donor = insert(:user, %{email: "camonz@camonz.com"})
        challenge = insert(:ngo_challenge, %{ngo: ngo, user: user, distance_target: 150, distance_covered: 51})
        donation_params = %{
          ngo_chal: challenge,
          ngo: ngo,
          user: donor,
          milestone: 2,
          milestone_distance: 50,
          str_cus_id: "cus_DYyQTnYmbkDjBV",
          str_src: "src_1D7qTcHjHTiyg867gAya4pe5"
        }

        insert(:donation, donation_params)

        {:ok, :challenge_updated} = ActivitiesIngestion.process_challenge({challenge.id, nil}, strava_activity)

        challenge = Repo.get(NGOChal, challenge.id) |> Repo.preload([:activities])

        assert length(challenge.activities) == 1
      end
    end
  end
end
