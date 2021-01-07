defmodule OmegaBravera.AccountsTest do
  use OmegaBravera.DataCase

  alias OmegaBravera.Accounts

  describe "organization" do
    alias OmegaBravera.Accounts.Organization

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def organization_fixture(attrs \\ %{}) do
      {:ok, organization} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_organization()

      organization
    end

    test "list_organization/0 returns all organization" do
      organization = organization_fixture()
      assert Accounts.list_organization() == [organization]
    end

    test "get_organization!/1 returns the organization with given id" do
      organization = organization_fixture()
      assert Accounts.get_organization!(organization.id) == organization
    end

    test "create_organization/1 with valid data creates a organization" do
      assert {:ok, %Organization{} = organization} = Accounts.create_organization(@valid_attrs)
      assert organization.name == "some name"
    end

    test "create_organization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_organization(@invalid_attrs)
    end

    test "update_organization/2 with valid data updates the organization" do
      organization = organization_fixture()

      assert {:ok, %Organization{} = organization} =
               Accounts.update_organization(organization, @update_attrs)

      assert organization.name == "some updated name"
    end

    test "update_organization/2 with invalid data returns error changeset" do
      organization = organization_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_organization(organization, @invalid_attrs)

      assert organization == Accounts.get_organization!(organization.id)
    end

    test "delete_organization/1 deletes the organization" do
      organization = organization_fixture()
      assert {:ok, %Organization{}} = Accounts.delete_organization(organization)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_organization!(organization.id) end
    end

    test "change_organization/1 returns a organization changeset" do
      organization = organization_fixture()
      assert %Ecto.Changeset{} = Accounts.change_organization(organization)
    end
  end

  describe "organization_members" do
    alias OmegaBravera.Accounts.OrganizationMember

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def organization_member_fixture(attrs \\ %{}) do
      {:ok, organization_member} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_organization_member()

      organization_member
    end

    test "list_organization_members/0 returns all organization_members" do
      organization_member = organization_member_fixture()
      assert Accounts.list_organization_members() == [organization_member]
    end

    test "get_organization_member!/1 returns the organization_member with given id" do
      organization_member = organization_member_fixture()
      assert Accounts.get_organization_member!(organization_member.id) == organization_member
    end

    test "create_organization_member/1 with valid data creates a organization_member" do
      assert {:ok, %OrganizationMember{} = organization_member} =
               Accounts.create_organization_member(@valid_attrs)
    end

    test "create_organization_member/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_organization_member(@invalid_attrs)
    end

    test "update_organization_member/2 with valid data updates the organization_member" do
      organization_member = organization_member_fixture()

      assert {:ok, %OrganizationMember{} = organization_member} =
               Accounts.update_organization_member(organization_member, @update_attrs)
    end

    test "update_organization_member/2 with invalid data returns error changeset" do
      organization_member = organization_member_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_organization_member(organization_member, @invalid_attrs)

      assert organization_member == Accounts.get_organization_member!(organization_member.id)
    end

    test "delete_organization_member/1 deletes the organization_member" do
      organization_member = organization_member_fixture()

      assert {:ok, %OrganizationMember{}} =
               Accounts.delete_organization_member(organization_member)

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_organization_member!(organization_member.id)
      end
    end

    test "change_organization_member/1 returns a organization_member changeset" do
      organization_member = organization_member_fixture()
      assert %Ecto.Changeset{} = Accounts.change_organization_member(organization_member)
    end
  end
end
