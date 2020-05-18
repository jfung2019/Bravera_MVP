defmodule OmegaBraveraWeb.UserChannel do
  use OmegaBraveraWeb, :channel
  @moduledoc """
  This channel is used to send notifications when users are connected
  over websocket.
  """

  def join(
        "user:" <> string_user_id,
        _payload,
        %{assigns: %{current_user: %{id: user_id}}} = socket
      ) do
    if authorized?(string_user_id, user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(string_user_id, user_id), do: String.to_integer(string_user_id) == user_id
end
