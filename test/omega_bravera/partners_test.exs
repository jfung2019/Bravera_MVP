defmodule OmegaBravera.PartnersTest do
  use OmegaBravera.DataCase, async: true
  alias OmegaBravera.{Fixtures, Partners}
  alias OmegaBravera.Partners.{Partner, PartnerLocation}

  describe "partner" do
    test "create_partner/1 with valid data creates a partner" do
      assert {:ok, %Partner{} = partner} =
               Partners.create_partner(%{
                 images: [],
                 introduction: "some introduction",
                 name: "some name",
                 opening_times: "some opening_times"
               })

      assert partner.images == []
      assert partner.introduction == "some introduction"
      assert partner.name == "some name"
      assert partner.opening_times == "some opening_times"
    end

    test "create_partner/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Partners.create_partner(%{
                 images: nil,
                 introduction: nil,
                 name: nil,
                 opening_times: nil
               })
    end
  end

  describe "partner created" do
    setup [:create_partner]

    test "list_partner/0 returns all partner", %{partner: %{id: partner_id}} do
      assert [%{id: ^partner_id}] = Partners.list_partner()
    end

    test "get_partner!/1 returns the partner with given id", %{partner: partner} do
      assert Partners.get_partner!(partner.id) == partner
    end

    test "update_partner/2 with valid data updates the partner", %{partner: partner} do
      assert {:ok, %Partner{} = partner} =
               Partners.update_partner(partner, %{
                 images: [],
                 introduction: "some updated introduction",
                 name: "some updated name",
                 opening_times: "some updated opening_times"
               })

      assert partner.images == []
      assert partner.introduction == "some updated introduction"
      assert partner.name == "some updated name"
      assert partner.opening_times == "some updated opening_times"
    end

    test "update_partner/2 with invalid data returns error changeset", %{partner: partner} do
      assert {:error, %Ecto.Changeset{}} =
               Partners.update_partner(partner, %{
                 images: nil,
                 introduction: nil,
                 name: nil,
                 opening_times: nil
               })

      assert partner == Partners.get_partner!(partner.id)
    end

    test "delete_partner/1 deletes the partner", %{partner: partner} do
      assert {:ok, %Partner{}} = Partners.delete_partner(partner)
      assert_raise Ecto.NoResultsError, fn -> Partners.get_partner!(partner.id) end
    end

    test "change_partner/1 returns a partner changeset", %{partner: partner} do
      assert %Ecto.Changeset{} = Partners.change_partner(partner)
    end
  end

  describe "partner_locations" do
    setup [:create_partner]

    test "create_partner_location/1 with valid data creates a partner_location", %{
      partner: partner
    } do
      assert {:ok, %PartnerLocation{} = partner_location} =
               Partners.create_partner_location(%{
                 address: "some address",
                 latitude: "120.5",
                 longitude: "120.5",
                 partner_id: partner.id
               })

      assert partner_location.address == "some address"
      assert partner_location.latitude == Decimal.new("120.5")
      assert partner_location.longitude == Decimal.new("120.5")
    end

    test "create_partner_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Partners.create_partner_location(%{address: nil, latitude: nil, longitude: nil})
    end
  end

  describe "partner_location created" do
    setup [:create_partner, :create_partner_location]

    test "list_partner_locations/0 returns all partner_locations", %{
      partner_location: partner_location
    } do
      assert Partners.list_partner_locations() == [partner_location]
    end

    test "get_partner_location!/1 returns the partner_location with given id", %{
      partner_location: partner_location
    } do
      assert Partners.get_partner_location!(partner_location.id) == partner_location
    end

    test "update_partner_location/2 with valid data updates the partner_location", %{
      partner_location: partner_location
    } do
      assert {:ok, %PartnerLocation{} = partner_location} =
               Partners.update_partner_location(partner_location, %{
                 address: "some updated address",
                 latitude: "456.7",
                 longitude: "456.7"
               })

      assert partner_location.address == "some updated address"
      assert partner_location.latitude == Decimal.new("456.7")
      assert partner_location.longitude == Decimal.new("456.7")
    end

    test "update_partner_location/2 with invalid data returns error changeset", %{
      partner_location: partner_location
    } do
      assert {:error, %Ecto.Changeset{}} =
               Partners.update_partner_location(partner_location, %{
                 address: nil,
                 latitude: nil,
                 longitude: nil
               })

      assert partner_location == Partners.get_partner_location!(partner_location.id)
    end

    test "delete_partner_location/1 deletes the partner_location", %{
      partner_location: partner_location
    } do
      assert {:ok, %PartnerLocation{}} = Partners.delete_partner_location(partner_location)

      assert_raise Ecto.NoResultsError, fn ->
        Partners.get_partner_location!(partner_location.id)
      end
    end

    test "change_partner_location/1 returns a partner_location changeset", %{
      partner_location: partner_location
    } do
      assert %Ecto.Changeset{} = Partners.change_partner_location(partner_location)
    end
  end

  defp create_partner(_), do: {:ok, partner: Fixtures.partner_fixture()}

  defp create_partner_location(%{partner: partner}),
    do: {:ok, partner_location: Fixtures.partner_location_fixture(%{partner_id: partner.id})}
end
