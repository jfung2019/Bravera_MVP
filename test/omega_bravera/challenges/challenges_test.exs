defmodule OmegaBravera.ChallengesTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.{Challenges, Fundraisers.NGO}

  describe "ngo_chals" do
    alias OmegaBravera.Challenges.NGOChal

    @valid_attrs %{
      "activity_type" => "Walk",
      "distance_target" => 50,
      "duration" => 42,
      "money_target" => "120.5",
      "slug" => "some slug",
      "status" => "",
      "type" => "Per Goal"
    }
    @update_attrs %{
      "activity_type" => "Run",
      "distance_target" => 75,
      "duration" => 43,
      "money_target" => "456.7",
      "slug" => "some updated slug",
      "status" => "some updated status",
      "type" => "Per Goal"
    }
    @invalid_attrs %{
      "activity_type" => nil,
      "distance_target" => "invalid",
      "duration" => "invalid",
      "money_target" => nil,
      "slug" => nil,
      "status" => nil,
      "type" => nil
    }

    def ngo_chal_fixture(_attrs \\ %{}) do
      insert(:ngo_challenge)
    end

    # TODO test if change set refuses a duplicate slug.

    test "inactive_for_five_days/0 returns the challenges that have been inactive for five days or more" do
      ngo = insert(:ngo)

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -6),
        slug: "John-325",
        ngo: ngo
      })

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -8),
        slug: "John-515",
        ngo: ngo
      })

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -2),
        slug: "Peter-411",
        ngo: ngo
      })

      result = Challenges.inactive_for_five_days()

      assert length(result) == 2
    end

    test "inactive_for_five_days/0 ignores the already notified challenges" do
      ngo = insert(:ngo)

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -6),
        slug: "John-325",
        ngo: ngo,
        participant_notified_of_inactivity: true
      })

      assert Challenges.inactive_for_five_days() == []
    end

    test "inactive_for_seven_days/0 returns the challenges that have been inactive for seven days or more" do
      ngo = insert(:ngo)

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -6),
        ngo: ngo
      })

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -8),
        ngo: ngo
      })

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -2),
        ngo: ngo
      })

      result = Challenges.inactive_for_seven_days()

      assert length(result) == 1
    end

    test "inactive_for_seven_days/0 ignores the already notified challenges" do
      ngo = insert(:ngo)

      insert(:ngo_challenge, %{
        last_activity_received: Timex.shift(Timex.now(), days: -10),
        slug: "John-325",
        ngo: ngo,
        donor_notified_of_inactivity: true
      })

      assert Challenges.inactive_for_seven_days() == []
    end

    test "list_ngo_chals/0 returns all ngo_chals" do
      %NGOChal{id: id} = ngo_chal_fixture()
      assert [%NGOChal{id: ^id}] = Challenges.list_ngo_chals()
    end

    test "get_ngo_chal!/1 returns the ngo_chal with given id" do
      ngo_chal = ngo_chal_fixture()
      %NGOChal{} = retrieved_chal = Challenges.get_ngo_chal!(ngo_chal.id)
      assert retrieved_chal.id == ngo_chal.id
    end

    test "create_ngo_chal/2 with valid data creates an active ngo_chal" do
      user = insert(:user)
      ngo = insert(:ngo)

      attrs = Map.merge(@valid_attrs, %{"user_id" => user.id, "ngo_id" => ngo.id})

      {:ok, %NGOChal{} = ngo_chal} = Challenges.create_ngo_chal(%NGOChal{}, ngo, attrs)

      assert ngo_chal.activity_type == "Walk"
      assert ngo_chal.distance_target == 50
      assert ngo_chal.duration == 42
      assert ngo_chal.money_target == Decimal.new("120.5")
      assert ngo_chal.slug == "some slug"
      assert ngo_chal.status == "active"
    end

    test "create_ngo_chal/2 with valid data creates a pre_registration ngo_chal" do
      user = insert(:user)
      ngo = insert(:ngo, %{open_registration: false})
      ngo = %{ngo | utc_launch_date: ngo.launch_date}

      attrs = Map.merge(@valid_attrs, %{"user_id" => user.id, "ngo_id" => ngo.id})

      {:ok, %NGOChal{} = ngo_chal} = Challenges.create_ngo_chal(%NGOChal{}, ngo, attrs)

      assert ngo_chal.start_date == ngo.launch_date
      assert ngo_chal.end_date == Timex.shift(ngo.launch_date, days: ngo_chal.duration)
      assert ngo_chal.activity_type == "Walk"
      assert ngo_chal.distance_target == 50
      assert ngo_chal.duration == 42
      assert ngo_chal.money_target == Decimal.new("120.5")
      assert ngo_chal.slug == "some slug"
      assert ngo_chal.status == "pre_registration"
    end

    test "create_ngo_chal/2 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Challenges.create_ngo_chal(%NGOChal{}, %NGO{}, @invalid_attrs)
    end

    test "update_ngo_chal/2 with valid data updates the ngo_chal" do
      ngo_chal = ngo_chal_fixture()

      {:ok, ngo_chal} = Challenges.update_ngo_chal(ngo_chal, @update_attrs)

      assert match?(%NGOChal{}, ngo_chal) == true

      assert ngo_chal.activity_type == "Run"
      assert ngo_chal.distance_target == 75
      assert ngo_chal.duration == 43
      assert ngo_chal.money_target == Decimal.new("456.7")
      assert ngo_chal.slug == "some updated slug"
      assert ngo_chal.status == "some updated status"
    end

    test "update_ngo_chal/2 with invalid data returns error changeset" do
      %NGOChal{id: id, updated_at: updated_at} = ngo_chal = ngo_chal_fixture()
      assert {:error, %Ecto.Changeset{}} = Challenges.update_ngo_chal(ngo_chal, @invalid_attrs)
      retrieved = Challenges.get_ngo_chal!(ngo_chal.id)
      assert %NGOChal{id: ^id, updated_at: ^updated_at} = retrieved
    end

    test "delete_ngo_chal/1 deletes the ngo_chal" do
      ngo_chal = ngo_chal_fixture()
      assert {:ok, %NGOChal{}} = Challenges.delete_ngo_chal(ngo_chal)
      assert_raise Ecto.NoResultsError, fn -> Challenges.get_ngo_chal!(ngo_chal.id) end
    end

    test "change_ngo_chal/1 returns a ngo_chal changeset" do
      ngo_chal = ngo_chal_fixture()
      assert %Ecto.Changeset{} = Challenges.change_ngo_chal(ngo_chal)
    end
  end
end
