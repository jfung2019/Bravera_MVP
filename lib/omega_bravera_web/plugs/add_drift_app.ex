defmodule OmegaBraveraWeb.AddDriftApp do

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    assign(conn, :add_drift?, true)
  end
end
