defmodule OmegaBraveraWeb.Api.Context do
  @behaviour Plug
  import Plug.Conn

  alias OmegaBravera.{Guardian, Accounts}

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    # IO.inspect [context: context]
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, data} <- Guardian.decode_and_verify(token),
         %{} = user <- get_user(data) do
      %{current_user: user}
    else
      _ ->
        %{}
    end
  end

  defp get_user(%{"sub" => "user:" <> id}), do: Accounts.get_user_with_everything!(id)
end
