defmodule OmegaBraveraWeb.GoogleAnalytics do
  import Plug.Conn, only: [assign: 3]

  def init(opts) do
    case Application.get_env(:omega_bravera, :env) do
      :prod ->
        Keyword.put(
          opts,
          :google_analytics_id,
          Application.get_env(:omega_bravera, :google_analytics_id)
        )

      _ ->
        opts
    end
  end

  def call(conn, google_analytics_id: ga_id), do: assign(conn, :google_analytics_id, ga_id)
  def call(conn, _opts), do: conn

  @doc """
  Adds a blocking noindex header for response to stop
  Google from indexing current page.
  """
  @spec block_index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def block_index(conn, opts \\ nil), do: Plug.Conn.put_resp_header(conn, "x-robots-tag", "noindex")
end
