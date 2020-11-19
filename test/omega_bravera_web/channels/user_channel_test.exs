defmodule OmegaBraveraWeb.UserChannelTest do
  use OmegaBraveraWeb.ChannelCase
  import OmegaBravera.Factory

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
end
