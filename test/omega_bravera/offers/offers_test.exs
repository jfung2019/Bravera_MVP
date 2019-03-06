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
      durations: [],
      full_desc: "some full_desc",
      ga_id: "some ga_id",
      hidden: true,
      image: "some image",
      logo: "some logo",
      name: "some name",
      offer_challenge_desc: "some offer_challenge_desc",
      offer_challenge_types: [],
      offer_percent: 120.5,
      open_registration: true,
      reward_value: 42,
      slug: "some slug",
      toc: "some toc",
      url: "https://bravera.co",
      user_id: nil
    }
    @update_attrs %{
      activities: [],
      additional_members: 43,
      currency: "hkd",
      desc: "some updated desc",
      distances: [],
      durations: [],
      full_desc: "some updated full_desc",
      ga_id: "some updated ga_id",
      hidden: false,
      image: "some updated image",
      logo: "some updated logo",
      name: "some updated name",
      offer_challenge_desc: "some updated offer_challenge_desc",
      offer_challenge_types: [],
      offer_percent: 456.7,
      open_registration: true,
      reward_value: 43,
      slug: "some updated slug",
      toc: "some updated toc",
      url: "https://staging.bravera.co"
    }
    @invalid_attrs %{
      activities: nil,
      additional_members: nil,
      currency: nil,
      desc: nil,
      distances: nil,
      durations: nil,
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
      reward_value: nil,
      slug: nil,
      toc: nil,
      url: nil
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
      offer = offer_fixture()
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
      assert offer.durations == []
      assert offer.full_desc == "some full_desc"
      assert offer.ga_id == "some ga_id"
      assert offer.hidden == true
      assert offer.image == "some image"
      assert offer.logo == "some logo"
      assert offer.name == "some name"
      assert offer.offer_challenge_desc == "some offer_challenge_desc"
      assert offer.offer_challenge_types == []
      assert offer.offer_percent == 120.5
      assert offer.open_registration == true

      assert offer.reward_value == 42
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
      assert offer.durations == []
      assert offer.full_desc == "some updated full_desc"
      assert offer.ga_id == "some updated ga_id"
      assert offer.hidden == false
      assert offer.image == "some updated image"
      assert offer.logo == "some updated logo"
      assert offer.name == "some updated name"
      assert offer.offer_challenge_desc == "some updated offer_challenge_desc"
      assert offer.offer_challenge_types == []
      assert offer.offer_percent == 456.7
      assert offer.open_registration == true

      assert offer.reward_value == 43
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
      duration: 42,
      end_date: "2010-04-17T14:00:00Z",
      has_team: true,
      last_activity_received: "2010-04-17T14:00:00Z",
      participant_notified_of_inactivity: true,
      slug: "some slug",
      start_date: "2010-04-17T14:00:00Z",
      status: "some status",
      type: "some type"
    }
    @update_attrs %{
      activity_type: "some updated activity_type",
      default_currency: "some updated default_currency",
      distance_target: 43,
      duration: 43,
      end_date: "2011-05-18T15:01:01Z",
      has_team: false,
      last_activity_received: "2011-05-18T15:01:01Z",
      participant_notified_of_inactivity: false,
      slug: "some updated slug",
      start_date: "2011-05-18T15:01:01Z",
      status: "some updated status",
      type: "some updated type"
    }
    @invalid_attrs %{
      activity_type: nil,
      default_currency: nil,
      distance_target: nil,
      duration: nil,
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
      {:ok, offer_challenge} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Offers.create_offer_challenge()

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
      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.create_offer_challenge(@valid_attrs)

      assert offer_challenge.activity_type == "some activity_type"
      assert offer_challenge.default_currency == "some default_currency"
      assert offer_challenge.distance_target == 42
      assert offer_challenge.duration == 42
      assert offer_challenge.end_date == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert offer_challenge.has_team == true

      assert offer_challenge.last_activity_received ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")

      assert offer_challenge.participant_notified_of_inactivity == true
      assert offer_challenge.slug == "some slug"

      assert offer_challenge.start_date ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")

      assert offer_challenge.status == "some status"
      assert offer_challenge.type == "some type"
    end

    test "create_offer_challenge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Offers.create_offer_challenge(@invalid_attrs)
    end

    test "update_offer_challenge/2 with valid data updates the offer_challenge" do
      offer_challenge = offer_challenge_fixture()

      assert {:ok, %OfferChallenge{} = offer_challenge} =
               Offers.update_offer_challenge(offer_challenge, @update_attrs)

      assert offer_challenge.activity_type == "some updated activity_type"
      assert offer_challenge.default_currency == "some updated default_currency"
      assert offer_challenge.distance_target == 43
      assert offer_challenge.duration == 43
      assert offer_challenge.end_date == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert offer_challenge.has_team == false

      assert offer_challenge.last_activity_received ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")

      assert offer_challenge.participant_notified_of_inactivity == false
      assert offer_challenge.slug == "some updated slug"

      assert offer_challenge.start_date ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")

      assert offer_challenge.status == "some updated status"
      assert offer_challenge.type == "some updated type"
    end

    test "update_offer_challenge/2 with invalid data returns error changeset" do
      offer_challenge = offer_challenge_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Offers.update_offer_challenge(offer_challenge, @invalid_attrs)

      assert offer_challenge == Offers.get_offer_challenge!(offer_challenge.id)
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
end
