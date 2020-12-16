defmodule OmegaBraveraWeb.UserChannelTest do
  use OmegaBraveraWeb.ChannelCase
  import OmegaBravera.Factory
  import Ecto.Query
  alias OmegaBravera.{Groups, Fixtures}

  setup do
    {:ok, user: insert(:user)}
  end

  test "can join successfully", %{user: user} do
    assert {:ok, _, _socket} =
             socket(OmegaBraveraWeb.UserSocket, user.id, %{current_user: user})
             |> subscribe_and_join(OmegaBraveraWeb.UserChannel, "user:#{user.id}")
  end

  test "cannot join other users channel", %{user: user} do
    assert {:error, %{reason: "unauthorized"}} =
             socket(OmegaBraveraWeb.UserSocket, user.id, %{current_user: user})
             |> subscribe_and_join(OmegaBraveraWeb.UserChannel, "user:0")
  end

  describe "joined user channel" do
    setup %{user: user} do
      joined_partner = Fixtures.partner_fixture()
      @endpoint.subscribe("group_channel:#{joined_partner.id}")
      Groups.join_partner(joined_partner.id, user.id)
      not_joined_partner = Fixtures.partner_fixture()

      message =
        Fixtures.group_chat_message_fixture(%{group_id: joined_partner.id, user_id: user.id})

      {:ok, _, socket} =
        socket(OmegaBraveraWeb.UserSocket, user.id, %{current_user: user})
        |> subscribe_and_join(OmegaBraveraWeb.UserChannel, "user:#{user.id}")

      {:ok,
       socket: socket,
       joined_partner: joined_partner,
       not_joined_partner: not_joined_partner,
       message: message}
    end

    test "can get joined_groups with their users and last messages", %{
      joined_partner: %{id: partner_id},
      user: %{id: user_id},
      message: %{id: message_id}
    } do
      assert_push("joined_groups", %{
        groups: [
          %{id: ^partner_id, chat_messages: [%{id: ^message_id}], users: [%{id: ^user_id}]}
        ]
      })
    end

    test "can get all group channels", %{socket: socket, joined_partner: %{id: partner_id}} do
      ref = push(socket, "joined_groups", %{})
      assert_reply ref, :ok, %{groups: [%{id: ^partner_id}]}
    end

    test "can send out a message and get a broadcast of the newly created message", %{
      socket: socket,
      joined_partner: %{id: partner_id}
    } do
      message = "Hello World!"

      push(socket, "create_message", %{
        "message_params" => %{"group_id" => partner_id, "message" => message, "meta_data" => %{}}
      })

      assert_broadcast "new_message", %{
        message: %{message: ^message}
      }

      assert_push "new_message", %{message: %{message: ^message}}
    end

    test "can send back reply if bad data was sent", %{
      socket: socket,
      joined_partner: %{id: partner_id}
    } do
      ref =
        push(socket, "create_message", %{
          "message_params" => %{"group_id" => partner_id, "message" => nil, "meta_data" => %{}}
        })

      refute_broadcast "new_message", %{message: %OmegaBravera.Groups.ChatMessage{}}
      refute_push "new_message", %{message: %OmegaBravera.Groups.ChatMessage{}}
      assert_reply ref, :error, %{errors: %{message: ["can't be blank"]}}
    end

    test "won't allow user to send message in a group if they are not in that group", %{
      socket: socket,
      not_joined_partner: %{id: not_joined_partner_id}
    } do
      ref =
        push(socket, "create_message", %{
          "message_params" => %{
            "group_id" => not_joined_partner_id,
            "message" => nil,
            "meta_data" => %{}
          }
        })

      assert_reply ref, :error, %{errors: %{group_id: ["not allowed"]}}
      refute_push "new_message", %{message: %OmegaBravera.Groups.ChatMessage{}}
      assert_push "removed_group", %{group: %{id: ^not_joined_partner_id}}
    end

    test "when join new group and booted from group message is broadcasted", %{
      not_joined_partner: %{id: not_joined_partner_id},
      user: %{id: user_id}
    } do
      @endpoint.subscribe(OmegaBraveraWeb.UserChannel.user_channel(user_id))
      {:ok, member} = Groups.join_partner(not_joined_partner_id, user_id)
      assert_broadcast "joined_group", %{id: not_joined_partner_id}

      assert_push "joined_group", %{
        group: %{id: ^not_joined_partner_id, chat_messages: [], users: [%{id: ^user_id}]}
      }

      Groups.delete_partner_member(member)
      assert_broadcast "removed_group", %{id: ^not_joined_partner_id}
      assert_push "removed_group", %{group: %{id: ^not_joined_partner_id}}
    end

    test "can like and unlike a message", %{
      socket: socket,
      message: %{id: message_id},
      user: %{id: user_id}
    } do
      push(socket, "like_message", %{"message_id" => message_id})

      assert_broadcast "updated_message", %{
        message: %{id: ^message_id, meta_data: %{likes: [^user_id]}}
      }

      assert_push "updated_message", %{
        message: %{id: ^message_id, meta_data: %{likes: [^user_id]}}
      }

      push(socket, "like_message", %{"message_id" => message_id})
      assert_broadcast "updated_message", %{message: %{id: ^message_id}}
      assert_push "updated_message", %{message: %{id: ^message_id, meta_data: %{likes: []}}}
    end

    test "can add an emoji to a message", %{
      socket: socket,
      message: %{id: message_id},
      user: %{id: user_id}
    } do
      emoji = "🧑‍🦯"
      push(socket, "emoji_message", %{"message_id" => message_id, "emoji" => emoji})

      assert_broadcast "updated_message", %{
        message: %{id: ^message_id, meta_data: %{emoji: %{^emoji => [^user_id]}}}
      }

      assert_push "updated_message", %{
        message: %{id: ^message_id, meta_data: %{emoji: %{^emoji => [^user_id]}}}
      }

      push(socket, "emoji_message", %{"message_id" => message_id, "emoji" => emoji})
      assert_broadcast "updated_message", %{message: %{id: ^message_id}}
      assert_push "updated_message", %{message: %{id: ^message_id, meta_data: %{emoji: map}}}
      assert map_size(map) == 0
    end

    test "can delete old message", %{
      socket: socket,
      message: %{id: message_id, group_id: group_id}
    } do
      push(socket, "delete_message", %{"message_id" => message_id})
      # because tests are run in transaction, this never gets called properly,
      # so we need to manually call this
      OmegaBravera.PostgresListener.broadcast_deletion(message_id, group_id)
      assert_broadcast "deleted_message", %{message: %{id: ^message_id, group_id: ^group_id}}
      assert_push "deleted_message", %{message: %{id: ^message_id, group_id: ^group_id}}
    end

    test "can get unread message count", %{
      socket: socket,
      message: %{id: first_id, group_id: group_id},
      user: %{id: user_id}
    } do
      now = Timex.now()

      OmegaBravera.Repo.update_all(from(m in Groups.ChatMessage, where: m.id == ^first_id),
        set: [inserted_at: Timex.shift(now, days: -2)]
      )

      %{id: second_id} =
        Fixtures.group_chat_message_fixture(%{group_id: group_id, user_id: user_id})

      OmegaBravera.Repo.update_all(from(m in Groups.ChatMessage, where: m.id == ^second_id),
        set: [inserted_at: Timex.shift(now, days: -1)]
      )

      %{id: third_id} =
        Fixtures.group_chat_message_fixture(%{group_id: group_id, user_id: user_id})

      ref = push(socket, "unread_count", %{"message_ids" => [first_id, second_id, third_id]})
      assert_reply ref, :ok, %{unread_count: %{^first_id => 2, ^second_id => 1, ^third_id => 0}}
    end

    test "can get old messages", %{
      socket: socket,
      message: %{id: first_id, group_id: group_id},
      user: %{id: user_id}
    } do
      now = Timex.now()

      OmegaBravera.Repo.update_all(from(m in Groups.ChatMessage, where: m.id == ^first_id),
        set: [inserted_at: Timex.shift(now, days: -2)]
      )

      %{id: second_id} =
        Fixtures.group_chat_message_fixture(%{group_id: group_id, user_id: user_id})

      OmegaBravera.Repo.update_all(from(m in Groups.ChatMessage, where: m.id == ^second_id),
        set: [inserted_at: Timex.shift(now, days: -1)]
      )

      %{id: third_id} =
        Fixtures.group_chat_message_fixture(%{group_id: group_id, user_id: user_id})

      ref = push(socket, "previous_messages", %{"message_id" => third_id, "limit" => 1})
      assert_reply ref, :ok, %{messages: [%{id: ^second_id}]}

      ref = push(socket, "previous_messages", %{"message_id" => third_id, "limit" => 20})
      assert_reply ref, :ok, %{messages: [%{id: ^second_id}, %{id: ^first_id}]}
    end
  end
end
