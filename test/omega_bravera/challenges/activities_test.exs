defmodule OmegaBravera.Challenges.ActivitiesTest do
  use OmegaBravera.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import OmegaBravera.Factory

  alias OmegaBravera.{Challenges.NGOChal, Challenges.Activities, Repo}

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")
  end

  describe "process_challenge/2" do
    test "does nothing if the Strava activity distance is <= 0" do
      assert Activities.process_challenge({nil, nil}, %Strava.Activity{}) == {:ok, :nothing_done}
    end

    test "updates the challenge with the new covered distance" do
      challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(3.2)})

      {:ok, :challenge_updated} = Activities.process_challenge({challenge.id, nil}, %Strava.Activity{distance: 4200})
      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.distance_covered == Decimal.new(7.4)
    end

    test "updates the challenge status if the covered distance is greater than the target distance" do
      challenge = insert(:ngo_challenge, %{distance_covered: Decimal.new(46.5), distance_target: 50})

      {:ok, :challenge_updated} = Activities.process_challenge({challenge.id, nil}, %Strava.Activity{distance: 4200})
      updated_challenge = Repo.get!(NGOChal, challenge.id)

      assert updated_challenge.status == "complete"
    end

    test "charges the chargeable donations" do
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

        {:ok, :challenge_updated} = Activities.process_challenge({challenge.id, nil}, %Strava.Activity{distance: 4200})
      end
    end
  end
end
