defmodule OmegaBraveraWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: OmegaBraveraWeb.Api.Schema
  alias OmegaBravera.{Accounts, Devices, Guardian}
  alias OmegaBraveraWeb.Api.Auth
  require Logger

  ## Channels
  # channel "room:*", OmegaBraveraWeb.RoomChannel

  def connect(%{"authToken" => token}, socket) do
    case auth_socket(token) do
      {:ok, user, device} ->
        {:ok,
         Absinthe.Phoenix.Socket.put_options(socket,
           context: %{current_user: user, device: device}
         )}

      _ ->
        :error
    end
  end

  def connect(_params, socket) do
    {:ok, socket}
  end

  defp auth_socket(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, %{"sub" => "user:" <> id}} ->
        try do
          {:ok, Accounts.get_user!(id), nil}
        rescue
          exception ->
            Logger.warn(
              "API Context: Got valid token, but non-existing user in db. #{inspect(exception)}"
            )

            :error
        end

      _ ->
        case Auth.decrypt_token(token) do
          {:ok, {:device_uuid, device_uuid}} ->
            case Devices.get_device_by_uuid(device_uuid) do
              nil ->
                :error

              device ->
                {:ok, Accounts.get_user!(device.user_id), device}
            end

          _ ->
            :error
        end
    end
  end

  def id(_socket), do: nil
end
