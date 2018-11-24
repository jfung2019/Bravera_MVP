defmodule OmegaBravera.Factory do
  use ExMachina.Ecto, repo: OmegaBravera.Repo

  def user_factory do
    %OmegaBravera.Accounts.User{
      firstname: "John",
      lastname: "Doe",
      email: sequence(:email, &"john.doe.#{&1}@example.com")
    }
  end

  def strava_factory do
    %OmegaBravera.Trackers.Strava{
      athlete_id: 12_345_678,
      email: sequence(:email, &"john.doe.#{&1}@example.com"),
      firstname: "John",
      lastname: "Doe",
      token: "abcdef123456",
      user: build(:user)
    }
  end

  def ngo_factory do
    %OmegaBravera.Fundraisers.NGO{
      name: "Save the children worldwide",
      slug: sequence(:slug, &"swcc-#{&1}")
    }
  end

  def ngo_challenge_factory do
    %OmegaBravera.Challenges.NGOChal{
      activity_type: sequence(:activity_type, ["Walk", "Cycle", "Run", "Hike"]),
      distance_target: sequence(:distance_target, [50, 75, 150, 250]),
      start_date: Timex.now(),
      end_date: Timex.shift(Timex.now(), days: 5),
      duration: 5,
      status: "active",
      slug: "John-512",
      user: build(:user),
      ngo: build(:ngo)
    }
  end

  def activity_factory do
    %OmegaBravera.Challenges.Activity{
      strava_id: 1_836_709_368,
      distance: Decimal.new(1.74),
      start_date: ~N[2018-09-11 07:58:01],
      type: "Walk",
      name: "Morning Walk",
      manual: false,
      user: build(:user),
      challenge: build(:ngo_challenge)
    }
  end

  def donation_factory do
    %OmegaBravera.Money.Donation{
      amount: Decimal.new(10),
      currency: "HKD",
      str_src: "src_1D7qTcHjHTiyg867gAya4pe5",
      str_cus_id: "cus_DYyQTnYmbkDjBV",
      milestone: 1,
      status: "pending",
      milestone_distance: 0,
      user: build(:user),
      ngo: build(:ngo),
      ngo_chal: build(:ngo_challenge)
    }
  end
end
