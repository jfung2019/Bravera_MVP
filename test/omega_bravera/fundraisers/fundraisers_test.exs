defmodule OmegaBravera.FundraisersTest do
  use OmegaBravera.DataCase

  import OmegaBravera.Factory

  alias OmegaBravera.Fundraisers

  describe "ngos" do
    alias OmegaBravera.Fundraisers.NGO

    @valid_attrs %{
      desc: "some desc",
      logo: "some logo",
      image: "some image",
      url: "http://test.com",
      name: "some name",
      slug: "some slug",
      user_id: ""
    }
    @update_attrs %{
      desc: "some updated desc",
      logo: "some updated logo",
      name: "some updated name",
      slug: "some updated slug"
    }
    @invalid_attrs %{desc: nil, logo: nil, name: nil, slug: nil}

    def ngo_fixture(attrs \\ %{}) do
      user = insert(:user)
      {:ok, ngo} =
        attrs
        |> Enum.into(%{@valid_attrs | user_id: user.id})
        |> Fundraisers.create_ngo()

      ngo
    end

    test "list_ngos/0 returns all ngos" do
      ngo = ngo_fixture()
      assert Fundraisers.list_ngos() == [ngo]
    end

    test "get_ngo!/1 returns the ngo with given id" do
      ngo = ngo_fixture()
      assert Fundraisers.get_ngo!(ngo.id) == ngo
    end

    test "create_ngo/1 with valid data creates a ngo" do
      ngo = ngo_fixture()
      assert ngo.desc == "some desc"
      assert ngo.logo == "some logo"
      assert ngo.name == "some name"
      assert ngo.slug == "some slug"
    end

    test "create_ngo/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Fundraisers.create_ngo(@invalid_attrs)
    end

    test "update_ngo/2 with valid data updates the ngo" do
      ngo = ngo_fixture()
      assert {:ok, ngo} = Fundraisers.update_ngo(ngo, @update_attrs)
      assert %NGO{} = ngo
      assert ngo.desc == "some updated desc"
      assert ngo.logo == "some updated logo"
      assert ngo.name == "some updated name"
      assert ngo.slug == "some updated slug"
    end

    test "update_ngo/2 with invalid data returns error changeset" do
      ngo = ngo_fixture()
      assert {:error, %Ecto.Changeset{}} = Fundraisers.update_ngo(ngo, @invalid_attrs)
      assert ngo == Fundraisers.get_ngo!(ngo.id)
    end

    test "delete_ngo/1 deletes the ngo" do
      ngo = ngo_fixture()
      assert {:ok, %NGO{}} = Fundraisers.delete_ngo(ngo)
      assert_raise Ecto.NoResultsError, fn -> Fundraisers.get_ngo!(ngo.id) end
    end

    test "change_ngo/1 returns a ngo changeset" do
      ngo = ngo_fixture()
      assert %Ecto.Changeset{} = Fundraisers.change_ngo(ngo)
    end
  end
end
