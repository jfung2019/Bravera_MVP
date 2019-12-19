defmodule OmegaBravera.ReferralsTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.Referrals

  describe "referrals" do
    alias OmegaBravera.Referrals.Referral

    @valid_attrs %{bonus_points: 42, status: "pending_acceptance", token: "some token"}
    @invalid_attrs %{bonus_points: nil, status: nil, token: nil}

    def referral_fixture(attrs \\ %{}) do
      {:ok, referral} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Referrals.create_referral()

      referral
    end

    test "list_referrals/0 returns all referrals" do
      referral = referral_fixture()
      assert Referrals.list_referrals() == [referral]
    end

    test "get_referral!/1 returns the referral with given id" do
      referral = referral_fixture()
      assert Referrals.get_referral!(referral.id) == referral
    end

    test "create_referral/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Referrals.create_referral(@invalid_attrs)
    end

    test "update_referral/2 with invalid data returns error changeset" do
      referral = referral_fixture()
      assert {:error, %Ecto.Changeset{}} = Referrals.update_referral(referral, @invalid_attrs)
      assert referral == Referrals.get_referral!(referral.id)
    end

    test "delete_referral/1 deletes the referral" do
      referral = referral_fixture()
      assert {:ok, %Referral{}} = Referrals.delete_referral(referral)
      assert_raise Ecto.NoResultsError, fn -> Referrals.get_referral!(referral.id) end
    end

    test "change_referral/1 returns a referral changeset" do
      referral = referral_fixture()
      assert %Ecto.Changeset{} = Referrals.change_referral(referral)
    end
  end
end
