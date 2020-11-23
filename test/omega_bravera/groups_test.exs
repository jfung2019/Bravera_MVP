defmodule OmegaBravera.GroupsTest do
  use OmegaBravera.DataCase, async: true
  alias OmegaBravera.{Fixtures, Groups}
  alias Groups.{Partner, PartnerLocation, PartnerVote, ChatMessage}

  describe "partner" do
    test "create_partner/1 with valid data creates a partner" do
      assert {:ok, %Partner{} = partner} =
               Groups.create_partner(%{
                 images: [],
                 introduction: "some introduction",
                 name: "some name",
                 short_description: "some opening_times"
               })

      assert partner.images == []
      assert partner.introduction == "some introduction"
      assert partner.name == "some name"
      assert partner.short_description == "some opening_times"
    end

    test "create_partner/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Groups.create_partner(%{
                 images: nil,
                 introduction: nil,
                 name: nil,
                 short_description: nil
               })
    end
  end

  describe "partner created" do
    setup [:create_partner]

    test "list_partner/0 returns all partner", %{partner: %{id: partner_id}} do
      assert [%{id: ^partner_id}] = Groups.list_partner()
    end

    test "get_partner!/1 returns the partner with given id", %{partner: partner} do
      assert Groups.get_partner!(partner.id).id == partner.id
    end

    test "update_partner/2 with valid data updates the partner", %{partner: partner} do
      assert {:ok, %Partner{} = partner} =
               Groups.update_partner(partner, %{
                 images: [],
                 introduction: "some updated introduction",
                 name: "some updated name",
                 short_description: "some updated opening_times"
               })

      assert partner.images == []
      assert partner.introduction == "some updated introduction"
      assert partner.name == "some updated name"
      assert partner.short_description == "some updated opening_times"
    end

    test "update_partner/2 with invalid data returns error changeset", %{partner: partner} do
      assert {:error, %Ecto.Changeset{}} =
               Groups.update_partner(partner, %{
                 images: nil,
                 introduction: nil,
                 name: nil,
                 opening_times: nil
               })

      assert partner.updated_at == Groups.get_partner!(partner.id).updated_at
    end

    test "delete_partner/1 deletes the partner", %{partner: partner} do
      assert {:ok, %Partner{}} = Groups.delete_partner(partner)
      assert_raise Ecto.NoResultsError, fn -> Groups.get_partner!(partner.id) end
    end

    test "change_partner/1 returns a partner changeset", %{partner: partner} do
      assert %Ecto.Changeset{} = Groups.change_partner(partner)
    end
  end

  describe "partner_locations" do
    setup [:create_partner]

    test "create_partner_location/1 with valid data creates a partner_location", %{
      partner: partner
    } do
      assert {:ok, %PartnerLocation{} = partner_location} =
               Groups.create_partner_location(%{
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
               Groups.create_partner_location(%{address: nil, latitude: nil, longitude: nil})
    end
  end

  describe "partner_location created" do
    setup [:create_partner, :create_partner_location]

    test "list_partner_locations/0 returns all partner_locations", %{
      partner_location: partner_location
    } do
      assert Groups.list_partner_locations() == [partner_location]
    end

    test "get_partner_location!/1 returns the partner_location with given id", %{
      partner_location: partner_location
    } do
      assert Groups.get_partner_location!(partner_location.id) == partner_location
    end

    test "update_partner_location/2 with valid data updates the partner_location", %{
      partner_location: partner_location
    } do
      assert {:ok, %PartnerLocation{} = partner_location} =
               Groups.update_partner_location(partner_location, %{
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
               Groups.update_partner_location(partner_location, %{
                 address: nil,
                 latitude: nil,
                 longitude: nil
               })

      assert partner_location == Groups.get_partner_location!(partner_location.id)
    end

    test "delete_partner_location/1 deletes the partner_location", %{
      partner_location: partner_location
    } do
      assert {:ok, %PartnerLocation{}} = Groups.delete_partner_location(partner_location)

      assert_raise Ecto.NoResultsError, fn ->
        Groups.get_partner_location!(partner_location.id)
      end
    end

    test "change_partner_location/1 returns a partner_location changeset", %{
      partner_location: partner_location
    } do
      assert %Ecto.Changeset{} = Groups.change_partner_location(partner_location)
    end
  end

  describe "partner_votes" do
    setup [:create_user, :create_partner]

    test "create_partner_vote/1 with valid data creates a partner_vote", %{
      user: %{id: user_id},
      partner: %{id: partner_id}
    } do
      assert {:ok, %PartnerVote{}} =
               Groups.create_partner_vote(%{user_id: user_id, partner_id: partner_id})
    end

    test "create_partner_vote/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Groups.create_partner_vote(%{})
    end
  end

  describe "partner_votes created" do
    setup [:create_user, :create_partner, :create_partner_vote]

    test "list_partner_votes/0 returns all partner_votes", %{vote: partner_vote} do
      assert Groups.list_partner_votes() == [partner_vote]
    end

    test "get_partner_vote!/1 returns the partner_vote with given id", %{vote: partner_vote} do
      assert Groups.get_partner_vote!(partner_vote.id) == partner_vote
    end

    test "delete_partner_vote/1 deletes the partner_vote", %{vote: partner_vote} do
      assert {:ok, %PartnerVote{}} = Groups.delete_partner_vote(partner_vote)
      assert_raise Ecto.NoResultsError, fn -> Groups.get_partner_vote!(partner_vote.id) end
    end

    test "change_partner_vote/1 returns a partner_vote changeset", %{vote: partner_vote} do
      assert %Ecto.Changeset{} = Groups.change_partner_vote(partner_vote)
    end

    test "cannot create double votes for same user for same partner", %{
      vote: %{user_id: user_id, partner_id: partner_id}
    } do
      assert {:error, %Ecto.Changeset{}} =
               Groups.create_partner_vote(%{user_id: user_id, partner_id: partner_id})
    end
  end

  describe "group_chat_message created" do
    setup [:create_user, :create_partner, :create_chat_message]

    test "list_group_chat_messages/0 returns all group_chat_messages", %{
      chat_message: chat_message
    } do
      assert Groups.list_group_chat_messages() == [chat_message]
    end

    test "get_chat_message!/1 returns the chat_message with given id", %{
      chat_message: chat_message
    } do
      assert Groups.get_chat_message!(chat_message.id).id == chat_message.id
    end

    test "update_chat_message/2 with valid data updates the chat_message", %{
      chat_message: chat_message
    } do
      assert {:ok, %ChatMessage{} = chat_message} =
               Groups.update_chat_message(chat_message, %{meta_data: %{}})

      assert chat_message.meta_data == %OmegaBravera.Groups.ChatMessageMetaData{}
    end

    test "update_chat_message/2 with invalid data returns error changeset", %{
      chat_message: chat_message
    } do
      assert {:error, %Ecto.Changeset{}} =
               Groups.update_chat_message(chat_message, %{message: nil, meta_data: nil})

      assert chat_message.updated_at == Groups.get_chat_message!(chat_message.id).updated_at
    end

    test "delete_chat_message/1 deletes the chat_message", %{chat_message: chat_message} do
      assert {:ok, %ChatMessage{}} = Groups.delete_chat_message(chat_message)
      assert_raise Ecto.NoResultsError, fn -> Groups.get_chat_message!(chat_message.id) end
    end

    test "change_chat_message/1 returns a chat_message changeset", %{chat_message: chat_message} do
      assert %Ecto.Changeset{} = Groups.change_chat_message(chat_message)
    end
  end

  describe "group_chat_message" do
    setup [:create_user, :create_partner]

    test "create_chat_message/1 with valid data creates a chat_message", %{
      partner: %{id: partner_id},
      user: %{id: user_id}
    } do
      assert {:ok, %ChatMessage{} = chat_message} =
               Groups.create_chat_message(%{
                 message: "some message",
                 group_id: partner_id,
                 user_id: user_id,
                 meta_data: %{}
               })

      assert chat_message.message == "some message"
      assert chat_message.meta_data == %OmegaBravera.Groups.ChatMessageMetaData{}
    end

    test "create_chat_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Groups.create_chat_message(%{message: nil, meta_data: nil})
    end
  end

  defp create_user(_), do: {:ok, user: Fixtures.user_fixture()}

  defp create_partner_vote(%{partner: %{id: partner_id}, user: %{id: user_id}}),
    do: {:ok, vote: Fixtures.partner_vote_fixture(%{user_id: user_id, partner_id: partner_id})}

  defp create_partner(_), do: {:ok, partner: Fixtures.partner_fixture()}

  defp create_partner_location(%{partner: partner}),
    do: {:ok, partner_location: Fixtures.partner_location_fixture(%{partner_id: partner.id})}

  defp create_chat_message(%{user: %{id: user_id}, partner: %{id: partner_id}}),
    do:
      {:ok,
       chat_message:
         Fixtures.group_chat_message_fixture(%{group_id: partner_id, user_id: user_id})}
end
