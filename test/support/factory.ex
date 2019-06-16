defmodule OmegaBravera.Factory do
  use ExMachina.Ecto, repo: OmegaBravera.Repo

  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  def user_factory do
    %OmegaBravera.Accounts.User{
      firstname: "John",
      lastname: "Doe",
      email: sequence(:email, &"john.doe.#{&1}@example.com"),
      email_verified: true
    }
  end

  def credential_factory do
    %OmegaBravera.Accounts.Credential{
      password_hash: hashpwsalt("password"),
      user: build(:user)
    }
  end

  def strava_factory do
    %OmegaBravera.Trackers.Strava{
      athlete_id: Enum.random(10_000_000..20_000_000),
      email: sequence(:email, &"john.doe.#{&1}@example.com"),
      firstname: "John",
      lastname: "Doe",
      token: "abcd#{Enum.random(10_000_000..20_000_000)}",
      strava_profile_picture: "some-profile-picture.png",
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
      activities: ["Run", "Cycle", "Walk", "Hike"],
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

  def donor_factory do
    %OmegaBravera.Accounts.Donor{
      firstname: "John",
      lastname: "Wick",
      email: sequence(:email, &"john.wick.#{&1}@example.com")
    }
  end

  def donation_factory do
    %OmegaBravera.Money.Donation{
      amount: Decimal.new(150),
      type: "milestone",
      currency: "hkd",
      str_src: "src_1D7qTcHjHTiyg867gAya4pe5",
      str_cus_id: "cus_DYyQTnYmbkDjBV",
      milestone: 1,
      status: "pending",
      milestone_distance: 0,
      donor_pays_fees: false,
      charged_amount: Decimal.new(150),
      exchange_rate: Decimal.new(1),
      donor: build(:donor),
      ngo: build(:ngo),
      ngo_chal: build(:ngo_challenge)
    }
  end

  def km_donation_factory do
    %OmegaBravera.Money.Donation{
      amount: Decimal.new(5),
      type: "km",
      currency: "HKD",
      str_src: "src_1D7qTcHjHTiyg867gAya4pe4",
      str_cus_id: "cus_DYyQTnYmbkDjBZ",
      km_distance: 50,
      status: "pending",
      exchange_rate: Decimal.new(1),
      donor: build(:donor),
      ngo: build(:ngo),
      ngo_chal: build(:ngo_challenge)
    }
  end

  def team_factory do
    %OmegaBravera.Challenges.Team{
      name: "Team Save Stuff",
      slug: sequence(:slug, &"team-#{&1}"),
      count: 3,
      user: build(:user),
      challenge: build(:ngo_challenge, %{has_team: true})
    }
  end

  def offer_challenge_team_factory do
    %OmegaBravera.Offers.OfferChallengeTeam{
      name: "Team Save Stuff",
      slug: sequence(:slug, &"team-#{&1}"),
      count: 3,
      user: build(:user),
      offer_challenge: build(:offer_challenge, %{has_team: true})
    }
  end

  def team_member_factory do
    %OmegaBravera.Challenges.TeamMembers{
      team_id: nil,
      user_id: nil
    }
  end

  def offer_challenge_team_member_factory do
    %OmegaBravera.Offers.OfferChallengeTeamMembers{
      team_id: nil,
      user_id: nil
    }
  end

  def team_invitation_factory do
    %OmegaBravera.Challenges.TeamInvitations{
      email: sequence(:email, &"john.doe.#{&1}@example.com"),
      invitee_name: "Sherief Alaa",
      status: "pending_acceptance",
      token: "abcd#{Enum.random(10_000_000..20_000_000)}",
      team: build(:team)
    }
  end

  def offer_team_invitation_factory do
    %OmegaBravera.Offers.OfferChallengeTeamInvitation{
      email: sequence(:email, &"john.doe.#{&1}@example.com"),
      invitee_name: "Sherief Alaa",
      status: "pending_acceptance",
      token: "abcd#{Enum.random(10_000_000..20_000_000)}",
      team: build(:offer_challenge_team)
    }
  end

  def offer_factory do
    %OmegaBravera.Offers.Offer{
      name: "Save the children worldwide",
      slug: sequence(:slug, &"swcc-#{&1}"),
      pre_registration_start_date: Timex.now("Asia/Hong_Kong"),
      open_registration: true,
      start_date: Timex.now("Asia/Hong_Kong"),
      end_date: Timex.shift(Timex.now("Asia/Hong_Kong"), days: 10),
      always: false,
      additional_members: 0,
      logo: "/logo.png",
      image: "/image.png",
      url: "http://test.com",
      offer_challenge_types: ["PER_KM"],
      distances: ["50"],
      activities: ["Run", "Cycle"],
      time_limit: 0,
      toc: "foo",
      payment_amount: Decimal.new(0),
      vendor: build(:vendor)
    }
  end

  def offer_challenge_factory do
    %OmegaBravera.Offers.OfferChallenge{
      activity_type: "Run",
      default_currency: "HKD",
      distance_target: 42,
      has_team: false,
      last_activity_received: Timex.now("Asia/Hong_Kong"),
      participant_notified_of_inactivity: false,
      slug: "some slug",
      start_date: Timex.now(),
      end_date: Timex.shift(Timex.now(), days: 5),
      status: "active",
      type: "PER_KM",
      offer: build(:offer, %{additional_members: 0}),
      user: build(:user)
    }
  end

  def offer_reward_factory do
    %OmegaBravera.Offers.OfferReward{
      name: "Apple Watch",
      value: 350,
      offer: build(:offer)
    }
  end

  def vendor_factory do
    %OmegaBravera.Offers.OfferVendor{
      vendor_id: Enum.random(10_000_000..20_000_000) |> Integer.to_string(),
      email: sequence(:email, &"john.wick.#{&1}@example.com")
    }
  end

  def offer_redeem_factory do
    user = insert(:user)
    vendor = insert(:vendor)
    offer = insert(:offer, %{additional_members: 5, vendor: nil, vendor_id: vendor.id})
    offer_reward = insert(:offer_reward, %{offer: nil, offer_id: offer.id})

    offer_challenge =
      insert(:offer_challenge, %{
        offer: nil,
        offer_id: offer.id,
        user: nil,
        user_id: user.id,
        has_team: true
      })

    %OmegaBravera.Offers.OfferRedeem{
      vendor: vendor,
      offer: offer,
      user: user,
      offer_challenge: offer_challenge,
      offer_reward: offer_reward,
      token: Enum.random(10_000_000..20_000_000) |> Integer.to_string()
    }
  end
end
