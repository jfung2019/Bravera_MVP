defmodule OmegaBravera.OffersTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Offers

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
      image: "some image",
      logo: "some logo",
      name: "some name",
      offer_challenge_desc: "some offer_challenge_desc",
      offer_challenge_types: [],
      offer_percent: 120.5,
      open_registration: true,
      slug: "some slug",
      toc: "some toc",
      url: "https://bravera.co",
      user_id: nil,
      start_date: Timex.now(),
      end_date: Timex.now()
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
      image: "some updated image",
      logo: "some updated logo",
      name: "some updated name",
      offer_challenge_desc: "some updated offer_challenge_desc",
      offer_challenge_types: [],
      offer_percent: 456.7,
      open_registration: true,
      slug: "some updated slug",
      toc: "some updated toc",
      url: "https://staging.bravera.co",
      start_date: Timex.shift(Timex.now(), days: 1),
      end_date: Timex.shift(Timex.now(), days: 1)
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
      image: nil,
      launch_date: nil,
      logo: nil,
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
      end_date: nil
    }

    def offer_fixture(attrs \\ %{}) do
      user = insert(:user)

      {:ok, offer} =
        attrs
        |> Enum.into(%{@valid_attrs | user_id: user.id})
        |> Offers.create_offer()

      offer
    end

    def create_offer(attrs) do
      Map.put(attrs, :user_id, insert(:user).id)
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
      assert offer.image == "some image"
      assert offer.logo == "some logo"
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
      assert offer.image == "some updated image"
      assert offer.logo == "some updated logo"
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
      type: "PER_KM"
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
        |> Map.put(:user_id, offer.user_id)
        |> Enum.into(@valid_attrs)

      {:ok, offer_challenge} =
        offer
        |> Offers.create_offer_challenge(attrs)

      offer_challenge
    end

    test "list_offer_challenges/0 returns all offer_challenges" do
      offer_challenge = offer_challenge_fixture()
      assert Offers.list_offer_challenges() == [offer_challenge]
    end

    test "get_offer_challenge!/1 returns the offer_challenge with given id" do
      offer_challenge = offer_challenge_fixture()
      assert Offers.get_offer_challenge!(offer_challenge.id) == offer_challenge
    end

    test "create_offer_challenge/1 with valid data creates a offer_challenge" do
      offer = insert(:offer)

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(
                 offer,
                 Map.put(@valid_attrs, :user_id, offer.user_id)
               )

      assert offer_challenge.activity_type == "Run"
      assert offer_challenge.default_currency == "hkd"
      assert offer_challenge.distance_target == 50
      assert offer_challenge.participant_notified_of_inactivity == false
      assert offer_challenge.status == "active"
      assert offer_challenge.type == "PER_KM"
    end

    test "create_offer_challenge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Offers.create_offer_challenge(insert(:offer), @invalid_attrs)
    end

    test "delete_offer_challenge/1 deletes the offer_challenge" do
      offer_challenge = offer_challenge_fixture()
      assert {:ok, %OfferChallenge{}} = Offers.delete_offer_challenge(offer_challenge)
      assert_raise Ecto.NoResultsError, fn -> Offers.get_offer_challenge!(offer_challenge.id) end
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
      assert {:ok, %OfferReward{} = offer_reward} = Offers.create_offer_reward(Map.put(@valid_attrs, :offer_id, offer.id))
      assert offer_reward.name == "some name"
      assert offer_reward.value == 42
    end

    test "create_offer_reward/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Offers.create_offer_reward(@invalid_attrs)
    end

    test "update_offer_reward/2 with valid data updates the offer_reward" do
      offer_reward = offer_reward_fixture()
      assert {:ok, %OfferReward{} = offer_reward} = Offers.update_offer_reward(offer_reward, @update_attrs)
      assert offer_reward.name == "some updated name"
      assert offer_reward.value == 43
    end

    test "update_offer_reward/2 with invalid data returns error changeset" do
      offer_reward = offer_reward_fixture()
      assert {:error, %Ecto.Changeset{}} = Offers.update_offer_reward(offer_reward, @invalid_attrs)
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
end
