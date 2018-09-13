defmodule OmegaBravera.StripeTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.Stripe

  describe "str_customers" do
    alias OmegaBravera.Stripe.StrCustomer

    @valid_attrs %{cus_id: "some cus_id"}
    @update_attrs %{cus_id: "some updated cus_id"}
    @invalid_attrs %{cus_id: nil}

    def str_customer_fixture(attrs \\ %{}) do
      {:ok, str_customer} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Stripe.create_str_customer()

      str_customer
    end

    @tag :skip
    test "list_str_customers/0 returns all str_customers" do
      str_customer = str_customer_fixture()
      assert Stripe.list_str_customers() == [str_customer]
    end

    @tag :skip
    test "get_str_customer!/1 returns the str_customer with given id" do
      str_customer = str_customer_fixture()
      assert Stripe.get_str_customer!(str_customer.id) == str_customer
    end

    @tag :skip
    test "create_str_customer/1 with valid data creates a str_customer" do
      assert {:ok, %StrCustomer{} = str_customer} = Stripe.create_str_customer(@valid_attrs)
      assert str_customer.cus_id == "some cus_id"
    end

    test "create_str_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stripe.create_str_customer(@invalid_attrs)
    end

    @tag :skip
    test "update_str_customer/2 with valid data updates the str_customer" do
      str_customer = str_customer_fixture()
      assert {:ok, str_customer} = Stripe.update_str_customer(str_customer, @update_attrs)
      assert %StrCustomer{} = str_customer
      assert str_customer.cus_id == "some updated cus_id"
    end

    @tag :skip
    test "update_str_customer/2 with invalid data returns error changeset" do
      str_customer = str_customer_fixture()
      assert {:error, %Ecto.Changeset{}} = Stripe.update_str_customer(str_customer, @invalid_attrs)
      assert str_customer == Stripe.get_str_customer!(str_customer.id)
    end

    @tag :skip
    test "delete_str_customer/1 deletes the str_customer" do
      str_customer = str_customer_fixture()
      assert {:ok, %StrCustomer{}} = Stripe.delete_str_customer(str_customer)
      assert_raise Ecto.NoResultsError, fn -> Stripe.get_str_customer!(str_customer.id) end
    end

    @tag :skip
    test "change_str_customer/1 returns a str_customer changeset" do
      str_customer = str_customer_fixture()
      assert %Ecto.Changeset{} = Stripe.change_str_customer(str_customer)
    end
  end
end
