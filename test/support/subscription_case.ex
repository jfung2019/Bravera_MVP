defmodule OmegaBraveraWeb.SubscriptionCase do
  @moduledoc """
  This module defines the test case to be used by
  subscription tests
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      use OmegaBraveraWeb.ChannelCase

      use Absinthe.Phoenix.SubscriptionTest,
        schema: OmegaBraveraWeb.Api.Schema

      setup do
        {:ok, socket} = Phoenix.ChannelTest.connect(OmegaBraveraWeb.UserSocket, %{})
        {:ok, socket: socket}
      end
    end
  end
end
