defmodule OmegaBraveraWeb.UserChannelTest do
  use OmegaBraveraWeb.ChannelCase
  import OmegaBravera.Factory
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

      {:ok, _, socket} =
        socket(OmegaBraveraWeb.UserSocket, user.id, %{current_user: user})
        |> subscribe_and_join(OmegaBraveraWeb.UserChannel, "user:#{user.id}")

      {:ok,
       socket: socket, joined_partner: joined_partner, not_joined_partner: not_joined_partner}
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
        message: %OmegaBravera.Groups.ChatMessage{message: ^message}
      }

      assert_push "new_message", %{message: %OmegaBravera.Groups.ChatMessage{message: ^message}}
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
      assert_reply ref, :error, %{errors: %Ecto.Changeset{}}
    end
  end
end
