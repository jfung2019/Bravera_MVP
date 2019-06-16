defmodule OmegaBravera.OffersTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.{Offers, Accounts.User, Offers.OfferChallenge, Repo}

  describe "offers" do
    alias OmegaBravera.Offers.Offer

    @valid_attrs %{
      activities: [],
      additional_members: 42,
      currency: "gbp",
      desc: "some desc",
      distances: [],
      full_desc: "some full_desc",
      ga_id: "some ga_id",
      hidden: false,
      name: "some name",
      offer_challenge_desc: "some offer_challenge_desc",
      offer_challenge_types: [],
      offer_percent: 120.5,
      open_registration: true,
      slug: "some slug",
      toc: "some toc",
      url: "https://bravera.co",
      vendor_id: nil,
      start_date: Timex.now(),
      end_date: Timex.shift(Timex.now(), days: 5),
      payment_enabled: false,
      payment_amount: Decimal.new(0)
    }
    @update_attrs %{
      activities: [],
      additional_members: 43,
      currency: "hkd",
      desc: "some updated desc",
      distances: [],
      full_desc: "some updated full_desc",
      ga_id: "some updated ga_id",
      hidden: true,
      name: "some updated name",
      offer_challenge_desc: "some updated offer_challenge_desc",
      offer_challenge_types: [],
      offer_percent: 456.7,
      open_registration: true,
      slug: "some updated slug",
      toc: "some updated toc",
      url: "https://staging.bravera.co",
      start_date: Timex.shift(Timex.now(), days: 1),
      end_date: Timex.shift(Timex.now(), days: 10),
      payment_enabled: false,
      payment_amount: Decimal.new(0)
    }
    @invalid_attrs %{
      activities: nil,
      additional_members: nil,
      currency: nil,
      desc: nil,
      distances: nil,
      full_desc: nil,
      ga_id: nil,
      hidden: nil,
      launch_date: nil,
      name: nil,
      offer_challenge_desc: nil,
      offer_challenge_types: nil,
      offer_percent: nil,
      open_registration: nil,
      pre_registration_start_date: nil,
      slug: nil,
      toc: nil,
      url: nil,
      start_date: nil,
      end_date: nil,
      payment_enabled: false,
      payment_amount: Decimal.new(0)
    }

    def offer_fixture(attrs \\ %{}) do
      vendor = insert(:vendor)

      {:ok, offer} =
        attrs
        |> Enum.into(%{@valid_attrs | vendor_id: vendor.id})
        |> Offers.create_offer()

      offer
    end

    def create_offer(attrs) do
      Map.put(attrs, :vendor_id, insert(:vendor).id)
      |> Offers.create_offer()
    end

    test "list_offers/0 returns all offers" do
      offer = offer_fixture() |> Repo.preload(:offer_challenges)
      assert Offers.list_offers() == [offer]
    end

    test "get_offer!/1 returns the offer with given id" do
      offer = offer_fixture()
      assert Offers.get_offer!(offer.id) == offer
    end

    test "create_offer/1 with valid data creates a offer" do
      assert {:ok, %Offer{} = offer} = create_offer(@valid_attrs)
      assert offer.activities == []
      assert offer.additional_members == 42
      assert offer.currency == "gbp"
      assert offer.desc == "some desc"
      assert offer.distances == []
      assert offer.full_desc == "some full_desc"
      assert offer.ga_id == "some ga_id"
      assert offer.hidden == false
      assert offer.name == "some name"
      assert offer.offer_challenge_desc == "some offer_challenge_desc"
      assert offer.offer_challenge_types == []
      assert offer.offer_percent == 120.5
      assert offer.open_registration == true

      assert offer.slug == "some slug"
      assert offer.toc == "some toc"
      assert offer.url == "https://bravera.co"
    end

    test "create_offer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Offers.create_offer(@invalid_attrs)
    end

    test "update_offer/2 with valid data updates the offer" do
      offer = offer_fixture()
      assert {:ok, %Offer{} = offer} = Offers.update_offer(offer, @update_attrs)
      assert offer.activities == []
      assert offer.additional_members == 43
      assert offer.currency == "hkd"
      assert offer.desc == "some updated desc"
      assert offer.distances == []
      assert offer.full_desc == "some updated full_desc"
      assert offer.ga_id == "some updated ga_id"
      assert offer.hidden == true
      assert offer.name == "some updated name"
      assert offer.offer_challenge_desc == "some updated offer_challenge_desc"
      assert offer.offer_challenge_types == []
      assert offer.offer_percent == 456.7
      assert offer.open_registration == true

      assert offer.slug == "some updated slug"
      assert offer.toc == "some updated toc"
      assert offer.url == "https://staging.bravera.co"
    end

    test "update_offer/2 with invalid data returns error changeset" do
      offer = offer_fixture()
      assert {:error, %Ecto.Changeset{}} = Offers.update_offer(offer, @invalid_attrs)
      assert offer == Offers.get_offer!(offer.id)
    end

    test "delete_offer/1 deletes the offer" do
      offer = offer_fixture()
      assert {:ok, %Offer{}} = Offers.delete_offer(offer)
      assert_raise Ecto.NoResultsError, fn -> Offers.get_offer!(offer.id) end
    end

    test "change_offer/1 returns a offer changeset" do
      offer = offer_fixture()
      assert %Ecto.Changeset{} = Offers.change_offer(offer)
    end
  end

  describe "offer_challenges" do
    alias OmegaBravera.Offers.OfferChallenge

    @valid_attrs %{
      activity_type: "some activity_type",
      default_currency: "some default_currency",
      distance_target: 42,
      end_date: Timex.now(),
      has_team: true,
      last_activity_received: Timex.now(),
      participant_notified_of_inactivity: false,
      slug: "some slug",
      start_date: Timex.now(),
      status: "active",
      type: "PER_KM",
      offer_redeems: [%{}],
      team: %{},
      payment: %{}
    }
    @invalid_attrs %{
      activity_type: nil,
      default_currency: nil,
      distance_target: nil,
      end_date: nil,
      has_team: nil,
      last_activity_received: nil,
      participant_notified_of_inactivity: nil,
      slug: nil,
      start_date: nil,
      status: nil,
      type: nil
    }

    def offer_challenge_fixture(attrs \\ %{}) do
      offer = insert(:offer)

      attrs =
        attrs
        |> Enum.into(@valid_attrs)

      {:ok, offer_challenge} =
        offer
        |> Offers.create_offer_challenge(insert(:user), attrs)

      offer_challenge |> Repo.preload(:offer_redeems)
    end

    test "list_offer_challenges/0 returns all offer_challenges" do
      offer_challenge_fixture()
      assert length(Offers.list_offer_challenges()) == 1
    end

    test "get_offer_challenge!/1 returns the offer_challenge with given id" do
      offer_challenge = offer_challenge_fixture()
      assert Offers.get_offer_challenge!(offer_challenge.id).id == offer_challenge.id
    end

    test "create_offer_challenge/2 creates offer challenge with a team when offer additional members are greater than 0" do
      user = insert(:user)
      offer = insert(:offer, %{additional_members: 5})

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(offer, user)

      assert offer_challenge.team.count == offer.additional_members
      assert offer_challenge.team.user_id == user.id
    end

    test "create_offer_challenge/2 creates pre_registration challenge and uses today's date as a start_date instead of offer for it being in the past" do
      now = Timex.now()
      user = insert(:user)

      offer =
        insert(:offer, %{
          open_registration: false,
          pre_registration_start_date: Timex.shift(Timex.now(), days: -5),
          start_date: Timex.now(),
          end_date: Timex.shift(Timex.now(), days: 10),
          time_limit: 0
        })

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(offer, user)

      assert Timex.equal?(offer_challenge.start_date, now)
      assert Timex.equal?(offer_challenge.end_date, offer.end_date)
    end

    test "create_offer_challenge/2 can create offer_challenge with offer_redeem" do
      vendor = insert(:vendor)
      offer = insert(:offer, %{vendor: nil, vendor_id: vendor.id})
      insert(:offer_reward, %{offer: nil, offer_id: offer.id})
      user = insert(:user)

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(offer, user)
    end

    test "create_offer_challenge/2 can create offer_challenge with payment but only using a valid stripe token" do
      vendor = insert(:vendor)
      offer = insert(:offer, %{payment_enabled: true, payment_amount: Decimal.new(30), vendor: nil, vendor_id: vendor.id})
      insert(:offer_reward, %{offer: nil, offer_id: offer.id})
      user = insert(:user)

      assert {:error, reason} = Offers.create_offer_challenge(offer, user, %{team: %{}, offer_redeems: [%{}], payment: %{"stripe_token" => "tok_bad_token"}})
    end

    test "create_offer_challenge/2 can create offer_challenge with offer_redeem and team" do
      vendor = insert(:vendor)
      offer = insert(:offer, %{vendor: nil, vendor_id: vendor.id, additional_members: 4})
      insert(:offer_reward, %{offer: nil, offer_id: offer.id})
      user = insert(:user)

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(offer, user)

      assert length(offer_challenge.offer_redeems) == 1
      assert offer_challenge.team
      assert offer_challenge.team.count == 4
    end

    test "create_offer_challenge/2 with valid data creates a offer_challenge" do
      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(
                 insert(:offer, %{additional_members: 0}),
                 insert(:user),
                 @valid_attrs
               )

      assert offer_challenge.activity_type == "Run"
      assert offer_challenge.default_currency == "hkd"
      assert offer_challenge.distance_target == 50
      assert offer_challenge.participant_notified_of_inactivity == false
      assert offer_challenge.status == "active"
      assert offer_challenge.type == "PER_KM"

      offer_challenge = Repo.preload(offer_challenge, :team)
      assert is_nil(offer_challenge.team)
    end

    test "create_offer_challenge/2 can create offer_challenge with restricted end_date in respect to offer.time_limit" do
      vendor = insert(:vendor)

      offer =
        insert(:offer, %{
          vendor: nil,
          vendor_id: vendor.id,
          time_limit: 10,
          end_date: Timex.shift(Timex.now(), days: 30)
        })

      insert(:offer_reward, %{offer: nil, offer_id: offer.id})
      user = insert(:user)

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(offer, user)

      assert Timex.diff(offer_challenge.end_date, offer.end_date, :days) == -20
    end

    test "create_offer_challenge/2 can create offer_challenge with restricted end_date in respect to offer.time_limit and cannot bypass offer.end_date" do
      vendor = insert(:vendor)

      offer =
        insert(:offer, %{
          vendor: nil,
          vendor_id: vendor.id,
          time_limit: 10,
          end_date: Timex.shift(Timex.now(), days: 5)
        })

      insert(:offer_reward, %{offer: nil, offer_id: offer.id})
      user = insert(:user)

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(offer, user)

      assert Timex.diff(offer_challenge.end_date, offer.end_date, :days) == 0
    end

    test "create_offer_challenge/2 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Offers.create_offer_challenge(insert(:offer), %User{}, @invalid_attrs)
    end

    test "change_offer_challenge/1 returns a offer_challenge changeset" do
      offer_challenge = offer_challenge_fixture()
      assert %Ecto.Changeset{} = Offers.change_offer_challenge(offer_challenge)
    end
  end

  describe "offer_rewards" do
    alias OmegaBravera.Offers.OfferReward

    @valid_attrs %{name: "some name", value: 42}
    @update_attrs %{name: "some updated name", value: 43}
    @invalid_attrs %{name: nil, value: nil}

    def offer_reward_fixture(attrs \\ %{}) do
      offer = insert(:offer)

      {:ok, offer_reward} =
        attrs
        |> Map.put(:offer_id, offer.id)
        |> Enum.into(@valid_attrs)
        |> Offers.create_offer_reward()

      offer_reward
    end

    test "list_offer_rewards/0 returns all offer_rewards" do
      offer_reward = offer_reward_fixture()
      assert Offers.list_offer_rewards() == [offer_reward]
    end

    test "get_offer_reward!/1 returns the offer_reward with given id" do
      offer_reward = offer_reward_fixture()
      assert Offers.get_offer_reward!(offer_reward.id) == offer_reward
    end

    test "create_offer_reward/1 with valid data creates a offer_reward" do
      offer = insert(:offer)

      assert {:ok, %OfferReward{} = offer_reward} =
               Offers.create_offer_reward(Map.put(@valid_attrs, :offer_id, offer.id))

      assert offer_reward.name == "some name"
      assert offer_reward.value == 42
    end

    test "create_offer_reward/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Offers.create_offer_reward(@invalid_attrs)
    end

    test "update_offer_reward/2 with valid data updates the offer_reward" do
      offer_reward = offer_reward_fixture()

      assert {:ok, %OfferReward{} = offer_reward} =
               Offers.update_offer_reward(offer_reward, @update_attrs)

      assert offer_reward.name == "some updated name"
      assert offer_reward.value == 43
    end

    test "update_offer_reward/2 with invalid data returns error changeset" do
      offer_reward = offer_reward_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Offers.update_offer_reward(offer_reward, @invalid_attrs)

      assert offer_reward == Offers.get_offer_reward!(offer_reward.id)
    end

    test "delete_offer_reward/1 deletes the offer_reward" do
      offer_reward = offer_reward_fixture()
      assert {:ok, %OfferReward{}} = Offers.delete_offer_reward(offer_reward)
      assert_raise Ecto.NoResultsError, fn -> Offers.get_offer_reward!(offer_reward.id) end
    end

    test "change_offer_reward/1 returns a offer_reward changeset" do
      offer_reward = offer_reward_fixture()
      assert %Ecto.Changeset{} = Offers.change_offer_reward(offer_reward)
    end
  end

  describe "offer_redeems" do
    alias OmegaBravera.Offers.OfferRedeem

    test "list_offer_redeems/0 returns all offer_redeems" do
      _offer_redeem = insert(:offer_redeem)
      assert length(Offers.list_offer_redeems()) == 1
    end

    test "create_offer_redeems/4 with valid data creates a offer_redeems" do
      vendor = insert(:vendor)
      offer = insert(:offer, %{vendor: nil, vendor_id: vendor.id})
      offer_reward = insert(:offer_reward, %{offer: nil, offer_id: offer.id})
      user = build(:user)

      offer_challenge =
        insert(:offer_challenge, %{
          offer: nil,
          offer_id: offer.id,
          user: nil,
          user_id: user.id,
          has_team: false
        })

      assert {:ok, %OfferRedeem{} = offer_redeems} =
               Offers.create_offer_redeems(offer_challenge, vendor, %{
                 offer_reward_id: offer_reward.id
               })
    end

    test "create_offer_redeems/4 with nil vendor returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               Offers.create_offer_redeems(%OfferChallenge{}, nil, %{})

      assert [{:vendor_id, {"Your Vendor ID seems to be incorrect.", _}}] = errors
    end
  end

  describe "offer_vendors" do
    alias OmegaBravera.Offers.OfferVendor

    @valid_attrs %{vendor_id: "some vendor_id", email: "some@email.com"}
    @update_attrs %{vendor_id: "some updated vendor_id", email: "some2@email.com"}
    @invalid_attrs %{vendor_id: nil, email: nil}

    def offer_vendor_fixture(attrs \\ %{}) do
      {:ok, offer_vendor} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Offers.create_offer_vendor()

      offer_vendor
    end

    test "list_offer_vendors/0 returns all offer_vendors" do
      offer_vendor = offer_vendor_fixture()
      assert Offers.list_offer_vendors() == [offer_vendor]
    end

    test "get_offer_vendor!/1 returns the offer_vendor with given id" do
      offer_vendor = offer_vendor_fixture()
      assert Offers.get_offer_vendor!(offer_vendor.id) == offer_vendor
    end

    test "create_offer_vendor/1 with valid data creates a offer_vendor" do
      assert {:ok, %OfferVendor{} = offer_vendor} = Offers.create_offer_vendor(@valid_attrs)
      assert offer_vendor.vendor_id == "some vendor_id"
    end

    test "create_offer_vendor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Offers.create_offer_vendor(@invalid_attrs)
    end

    test "update_offer_vendor/2 with valid data updates the offer_vendor" do
      offer_vendor = offer_vendor_fixture()

      assert {:ok, %OfferVendor{} = offer_vendor} =
               Offers.update_offer_vendor(offer_vendor, @update_attrs)

      assert offer_vendor.vendor_id == "some updated vendor_id"
    end

    test "update_offer_vendor/2 with invalid data returns error changeset" do
      offer_vendor = offer_vendor_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Offers.update_offer_vendor(offer_vendor, @invalid_attrs)

      assert offer_vendor == Offers.get_offer_vendor!(offer_vendor.id)
    end

    test "delete_offer_vendor/1 deletes the offer_vendor" do
      offer_vendor = offer_vendor_fixture()
      assert {:ok, %OfferVendor{}} = Offers.delete_offer_vendor(offer_vendor)
      assert_raise Ecto.NoResultsError, fn -> Offers.get_offer_vendor!(offer_vendor.id) end
    end

    test "change_offer_vendor/1 returns a offer_vendor changeset" do
      offer_vendor = offer_vendor_fixture()
      assert %Ecto.Changeset{} = Offers.change_offer_vendor(offer_vendor)
    end
  end

  describe "offer_challenge_teams" do
    test "create_offer_challenge_with_team/4 creates offer challenge with team" do
      team1_params = %{name: "team 7", count: "4"}

      assert {:ok, record} =
               Offers.create_offer_challenge_with_team(
                 %OfferChallenge{},
                 insert(:offer),
                 insert(:user),
                 %{team: team1_params, offer_redeems: [%{}]}
               )

      assert record.team.count == 4

      team2_params = %{name: "team 5"}

      assert {:ok, record2} =
               Offers.create_offer_challenge_with_team(
                 %OfferChallenge{},
                 insert(:offer, %{additional_members: 7}),
                 insert(:user),
                 %{team: team2_params, offer_redeems: [%{}]}
               )

      assert record2.team.count == 7

      assert {:ok, record3} =
               Offers.create_offer_challenge_with_team(
                 %OfferChallenge{},
                 insert(:offer, %{additional_members: 3}),
                 insert(:user),
                 %{team: %{}, offer_redeems: [%{}]}
               )

      refute is_nil(record3.team.name)
      refute is_nil(record3.team.count)
      refute is_nil(record3.team.slug)
    end
  end

  describe "offer team members" do
    alias OmegaBravera.{Offers.OfferChallengeTeamMembers}

    test "adds an existing user to an existing team" do
      invitation =
        insert(
          :offer_team_invitation,
          %{
            invitee_name: "Sherief Alaa",
            email: "sheriefalaa.w@gmail.com"
          }
        )

      new_team_member =
        insert(
          :user,
          %{
            firstname: "Sherief",
            lastname: "Alaa",
            email: "sheriefalaa.w@gmail.com"
          }
        )

      assert {:ok, %OfferChallengeTeamMembers{} = team_with_member} =
               Offers.add_user_to_team(
                 invitation,
                 invitation.team,
                 new_team_member,
                 invitation.team.offer_challenge.user
               )

      assert team_with_member.team_id == invitation.team.id
      assert team_with_member.user_id == new_team_member.id
    end
  end
end
