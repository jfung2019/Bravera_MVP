defmodule OmegaBraveraWeb.Api.Context do
  @behaviour Plug
  import Plug.Conn

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
        {:ok, Accounts.get_user_with_everything!(id), nil}

      _ ->
        case Auth.decrypt_token(token) do
          {:ok, {:device_uuid, device_uuid}} ->
            device = Devices.get_device_by_uuid(device_uuid)
            {:ok, Accounts.get_user_with_everything!(device.user_id), device}

          _ ->
            :error
        end
    end
  end
end
