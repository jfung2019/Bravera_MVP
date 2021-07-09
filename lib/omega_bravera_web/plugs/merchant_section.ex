defmodule OmegaBraveraWeb.MerchantSection do
  import Plug.Conn, only: [assign: 3]

  def init(opts), do: opts

  def call(conn, _opts), do: assign(conn, :account_type, :merchant)
end
