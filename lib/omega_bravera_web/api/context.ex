defmodule OmegaBraveraWeb.Api.Context do
  @behaviour Plug
  import Plug.Conn
  require Logger

  alias OmegaBravera.{Guardian, Accounts, Devices}
  alias OmegaBraveraWeb.Api.Auth

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    # IO.inspect [context: context]
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user, device} <- get_user_device(token) do
      %{current_user: user, device: device}
    else
      _ ->
        %{}
    end
  end

  defp get_user_device(token) do
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
end
