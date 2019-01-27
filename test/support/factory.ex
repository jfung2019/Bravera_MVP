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
      athlete_id: Enum.random(10_000_000..20_000_000),
      email: sequence(:email, &"john.doe.#{&1}@example.com"),
      firstname: "John",
      lastname: "Doe",
      token: "abcd#{Enum.random(10_000_000..20_000_000)}",
      profile_picture: "some-profile-picture.png",
      user: build(:user)
    }
  end

  def ngo_factory do
    %OmegaBravera.Fundraisers.NGO{
      name: "Save the children worldwide",
      slug: sequence(:slug, &"swcc-#{&1}"),
      pre_registration_start_date: Timex.now("Asia/Hong_Kong"),
      launch_date: Timex.shift(Timex.now("Asia/Hong_Kong"), days: 10),
      minimum_donation: 500,
      additional_members: 0,
      open_registration: true,
      logo: "/logo.png",
      image: "/image.png",
      url: "http://test.com",
      user: build(:user)
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
      slug: sequence(:slug, &"sherief-#{&1}"),
      type: "PER_MILESTONE",
      user: build(:user),
      ngo: build(:ngo)
    }
  end

  def activity_factory do
    %OmegaBravera.Challenges.Activity{
      strava_id: 1_836_709_368,
      distance: Decimal.from_float(1.74),
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
      amount: Decimal.new(150),
      currency: "hkd",
      str_src: "src_1D7qTcHjHTiyg867gAya4pe5",
      str_cus_id: "cus_DYyQTnYmbkDjBV",
      milestone: 1,
      status: "pending",
      milestone_distance: 0,
      donor_pays_fees: false,
      charged_amount: Decimal.new(150),
      exchange_rate: Decimal.new(1),
      user: build(:user),
      ngo: build(:ngo),
      ngo_chal: build(:ngo_challenge)
    }
  end

  def km_donation_factory do
    %OmegaBravera.Money.Donation{
      amount: Decimal.new(5),
      currency: "HKD",
      str_src: "src_1D7qTcHjHTiyg867gAya4pe4",
      str_cus_id: "cus_DYyQTnYmbkDjBZ",
      km_distance: 50,
      status: "pending",
      exchange_rate: Decimal.new(1),
      user: build(:user),
      ngo: build(:ngo),
      ngo_chal: build(:ngo_challenge)
    }
  end

  def team_factory do
    %OmegaBravera.Challenges.Team{
      name: "Team Save Stuff",
      slug: sequence(:slug, &"team-#{&1}"),
      count: 3,
      invite_tokens: [
        "9BG57484A5h2vaAvL9oEn-lf-kU-sH4y",
        "j81_R7fKBZSwEwPmU1YHV0_cWChIY4IS",
        "x78_12fKBZSwEwPmU1Y223_XyBaskdn1"
      ],
      user: build(:user),
      challenge: build(:ngo_challenge, %{has_team: true})
    }
  end

  def team_member_factory do
    %OmegaBravera.Challenges.TeamMembers{
      team_id: nil,
      user_id: nil,
    }
  end
end
