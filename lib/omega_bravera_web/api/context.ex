defmodule OmegaBraveraWeb.Api.Context do
  @behaviour Plug
  import Plug.Conn
  require Logger

  alias OmegaBravera.{Guardian, Accounts, Devices}
  alias OmegaBraveraWeb.Api.Auth

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
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
    try do
      with {:ok, %{"sub" => "user:" <> id}} <- Guardian.decode_and_verify(token),
           %{} = user <- Accounts.get_not_deleted_user!(id) do
        {:ok, user, nil}
      else
        _ ->
          with {:ok, {:device_uuid, device_uuid}} <- Auth.decrypt_token(token),
               %{} = device <- Devices.get_device_by_uuid(device_uuid),
               %{} = user <- Accounts.get_not_deleted_user!(id) do
            {:ok, user, device}
          else
            _ ->
              :error
          end
      end
    rescue
      exception ->
        Logger.warn(
          "API Context: Got valid token, but non-existing or deleted user in db. #{inspect(exception)}"
        )

        :error
    end
  end
end
