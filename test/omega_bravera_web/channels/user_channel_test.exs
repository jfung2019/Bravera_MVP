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
      {:ok, _, socket} =
        socket(OmegaBraveraWeb.UserSocket, user.id, %{current_user: user})
        |> subscribe_and_join(OmegaBraveraWeb.UserChannel, "user:#{user.id}")
      joined_partner = Fixtures.partner_fixture()
      Groups.join_partner(joined_partner.id, user.id)
      not_joined_partner = Fixtures.partner_fixture()
      {:ok, socket: socket, joined_partner: joined_partner, not_joined_partner: not_joined_partner}
    end

    test "can get all group channels", %{socket: socket, joined_partner: %{id: partner_id}} do
      ref = push(socket, "joined_groups", %{})
      assert_reply ref, :ok, %{groups: [%{id: ^partner_id}]}
    end
  end
end
