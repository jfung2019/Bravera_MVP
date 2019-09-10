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
         {:ok, %{"sub" => "user:" <> id}} <- Guardian.decode_and_verify(token),
         %{} = user <- Accounts.get_user_with_everything!(id) do
      %{current_user: user}
    else
      _ ->
        %{}
    end
  end
end
