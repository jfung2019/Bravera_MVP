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
         {:ok, %{"sub" => "user:" <> id}} <- Guardian.decode_and_verify(token),
         %{} = user <- Accounts.get_user_with_everything!(id) do
      case get_req_header(conn, "device") do
        ["Device " <> device_token] ->
          case Auth.decrypt_token(device_token) do
            {:ok, {:device_uuid, device_uuid}} ->
              %{current_user: user, device: Devices.get_device_by_uuid(device_uuid)}

            _ ->
              %{current_user: user, device: nil}
          end

        _ ->
          %{current_user: user, device: nil}
      end
    else
      _ ->
        %{}
    end
  end
end
