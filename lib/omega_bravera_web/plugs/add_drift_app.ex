defmodule OmegaBraveraWeb.AddDriftApp do

  import Plug.Conn

  def init(opts) do
    case Application.get_env(:omega_bravera, :env) do
      :prod ->
        Keyword.put(
          opts,
          :drift_id,
          Application.get_env(:omega_bravera, :drift_id)
        )

      _ ->
        opts
    end
  end

  def call(conn, drift_id: drift_id), do: assign(conn, :drift_id, drift_id)
  def call(conn, _opts), do: conn
end
