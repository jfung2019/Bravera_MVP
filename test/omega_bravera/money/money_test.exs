defmodule OmegaBravera.MoneyTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.Money

  describe "donations" do
    alias OmegaBravera.Money.Donation

    @valid_attrs %{amount: "120.5", currency: "some currency", milestone: 42, status: "some status", str_src: "some str_src"}
    @update_attrs %{amount: "456.7", currency: "some updated currency", milestone: 43, status: "some updated status", str_src: "some updated str_src"}
    @invalid_attrs %{amount: nil, currency: nil, milestone: nil, status: nil, str_src: nil}

    def donation_fixture(attrs \\ %{}) do
      {:ok, donation} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Money.create_donation()

      donation
    end

    test "list_donations/0 returns all donations" do
      donation = donation_fixture()
      assert Money.list_donations() == [donation]
    end

    test "get_donation!/1 returns the donation with given id" do
      donation = donation_fixture()
      assert Money.get_donation!(donation.id) == donation
    end

    test "create_donation/1 with valid data creates a donation" do
      assert {:ok, %Donation{} = donation} = Money.create_donation(@valid_attrs)
      assert donation.amount == Decimal.new("120.5")
      assert donation.currency == "some currency"
      assert donation.milestone == 42
      assert donation.status == "some status"
      assert donation.str_src == "some str_src"
    end

    test "create_donation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Money.create_donation(@invalid_attrs)
    end

    test "update_donation/2 with valid data updates the donation" do
      donation = donation_fixture()
      assert {:ok, donation} = Money.update_donation(donation, @update_attrs)
      assert %Donation{} = donation
      assert donation.amount == Decimal.new("456.7")
      assert donation.currency == "some updated currency"
      assert donation.milestone == 43
      assert donation.status == "some updated status"
      assert donation.str_src == "some updated str_src"
    end

    test "update_donation/2 with invalid data returns error changeset" do
      donation = donation_fixture()
      assert {:error, %Ecto.Changeset{}} = Money.update_donation(donation, @invalid_attrs)
      assert donation == Money.get_donation!(donation.id)
    end

    test "delete_donation/1 deletes the donation" do
      donation = donation_fixture()
      assert {:ok, %Donation{}} = Money.delete_donation(donation)
      assert_raise Ecto.NoResultsError, fn -> Money.get_donation!(donation.id) end
    end

    test "change_donation/1 returns a donation changeset" do
      donation = donation_fixture()
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
