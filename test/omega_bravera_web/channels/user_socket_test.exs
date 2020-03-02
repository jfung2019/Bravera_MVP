defmodule OmegaBraveraWeb.UserSocketTest do
  use OmegaBraveraWeb.ChannelCase, async: true
  import OmegaBravera.Factory

  test "can connect to absinthe with proper context" do
    user = insert(:user)
    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(user, %{})

    {:ok, socket} =
      Phoenix.ChannelTest.connect(OmegaBraveraWeb.UserSocket, %{"authToken" => token})

    assert %{assigns: %{absinthe: %{opts: [context: %{current_user: user}]}}} = socket
  end
end
