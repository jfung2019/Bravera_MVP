defmodule OmegaBraveraWeb.UserSocketTest do
  use OmegaBraveraWeb.ChannelCase, async: true

  alias OmegaBravera.{Accounts, Locations}

  test "can connect to absinthe with proper context" do
    {:ok, %{id: location_id}} =
      Locations.create_location(%{
        name_en: "location1",
        name_zh: "location1",
        longitude: 90,
        latitude: 30
      })

    {:ok, user} =
      Accounts.create_user(%{
        firstname: "user",
        lastname: "1",
        email: "user1@email.com",
        email_verified: true,
        location_id: location_id
      })

    {:ok, token, _} = OmegaBravera.Guardian.encode_and_sign(user, %{})

    {:ok, socket} =
      Phoenix.ChannelTest.connect(OmegaBraveraWeb.UserSocket, %{"authToken" => token})

    assert %{
             assigns: %{absinthe: %{opts: [context: %{current_user: ^user}]}, current_user: ^user}
           } = socket
  end
end
