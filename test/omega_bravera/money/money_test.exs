defmodule OmegaBravera.MoneyTest do
  use OmegaBravera.DataCase, async: true

  import OmegaBravera.Factory

  alias OmegaBravera.Money

  describe "donations" do
    alias OmegaBravera.Money.Donation

    @update_attrs %{amount: "100", currency: "USD", milestone: 43, status: "pending", str_src: "src_1234567"}
    @invalid_attrs %{amount: nil, currency: nil, milestone: nil, status: nil, str_src: nil}

    test "chargeable_donations_for_challenge/1" do
      user = insert(:user)
      ngo = insert(:ngo, %{slug: "swcc-1"})
      challenge = insert(:ngo_challenge, %{ngo: ngo, user: user, distance_target: 150, distance_covered: 51})

      params = %{ngo_chal: challenge, ngo: ngo}


      insert(:donation, Map.merge(params, %{status: "charged"}))
      insert(:donation, Map.merge(params, %{milestone: 3, milestone_distance: 100}))
      second_donation = insert(:donation, Map.merge(params, %{milestone: 2, milestone_distance: 50}))

      chargeable_donations = Money.chargeable_donations_for_challenge(challenge)

      assert length(chargeable_donations) == 1
      assert hd(chargeable_donations).id == second_donation.id
    end

    test "list_donations/0 returns all donations" do
      donation = insert(:donation)

      result = Money.list_donations()

      assert length(result) == 1
      assert hd(result).id == donation.id
    end

    test "get_donation!/1 returns the donation with given id" do
      donation = insert(:donation)
      result = Money.get_donation!(donation.id)

      assert result.id == donation.id
    end

    test "update_donation/2 with valid data updates the donation" do
      donation = insert(:donation)

      assert {:ok, donation} = Money.update_donation(donation, @update_attrs)
      assert match?(%Donation{}, donation) == true

      assert donation.amount == Decimal.new("100")
      assert donation.currency == "USD"
      assert donation.milestone == 43
      assert donation.status == "pending"
      assert donation.str_src == "src_1234567"
    end

    test "update_donation/2 with invalid data returns error changeset" do
      donation = insert(:donation)
      assert {:error, %Ecto.Changeset{}} = Money.update_donation(donation, @invalid_attrs)
    end

    test "delete_donation/1 deletes the donation" do
      donation = insert(:donation)

      assert {:ok, %Donation{}} = Money.delete_donation(donation)
      assert_raise Ecto.NoResultsError, fn -> Money.get_donation!(donation.id) end
    end

    test "change_donation/1 returns a donation changeset" do
      donation = insert(:donation)
      assert %Ecto.Changeset{} = Money.change_donation(donation)
    end
  end

  describe "tips" do
    alias OmegaBravera.Money.Tip

    @valid_attrs %{amount: 42, currency: "some currency"}
    @update_attrs %{amount: 43, currency: "some updated currency"}
    @invalid_attrs %{amount: nil, currency: nil}

    def tip_fixture(attrs \\ %{}) do
      {:ok, tip} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Money.create_tip()

      tip
    end

    test "list_tips/0 returns all tips" do
      tip = tip_fixture()
      assert Money.list_tips() == [tip]
    end

    test "get_tip!/1 returns the tip with given id" do
      tip = tip_fixture()
      assert Money.get_tip!(tip.id) == tip
    end

    test "create_tip/1 with valid data creates a tip" do
      assert {:ok, %Tip{} = tip} = Money.create_tip(@valid_attrs)
      assert tip.amount == 42
      assert tip.currency == "some currency"
    end

    test "create_tip/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Money.create_tip(@invalid_attrs)
    end

    test "update_tip/2 with valid data updates the tip" do
      tip = tip_fixture()
      assert {:ok, tip} = Money.update_tip(tip, @update_attrs)
      assert %Tip{} = tip
      assert tip.amount == 43
      assert tip.currency == "some updated currency"
    end

    test "update_tip/2 with invalid data returns error changeset" do
      tip = tip_fixture()
      assert {:error, %Ecto.Changeset{}} = Money.update_tip(tip, @invalid_attrs)
      assert tip == Money.get_tip!(tip.id)
    end

    test "delete_tip/1 deletes the tip" do
      tip = tip_fixture()
      assert {:ok, %Tip{}} = Money.delete_tip(tip)
      assert_raise Ecto.NoResultsError, fn -> Money.get_tip!(tip.id) end
    end

    test "change_tip/1 returns a tip changeset" do
      tip = tip_fixture()
      assert %Ecto.Changeset{} = Money.change_tip(tip)
    end
  end
end
