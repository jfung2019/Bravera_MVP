defmodule OmegaBraveraWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :omega_bravera
  use Absinthe.Phoenix.Endpoint

  @session_options [
    store: :cookie,
    key: "_omega_bravera_key",
    signing_salt: "U4QU74vj",
    max_age: Application.get_env(:omega_bravera, :cookie_age)
  ]

  socket "/socket", OmegaBraveraWeb.UserSocket, websocket: true

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :omega_bravera,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug Sentry.PlugContext

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  # Absinthe Debugging
  # plug :debug_response
  plug OmegaBraveraWeb.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end

  # Absinthe Debugging
  # defp debug_response(conn, _) do
  #   Plug.Conn.register_before_send(conn, fn conn ->
  #     conn.resp_body |> IO.inspect(label: :Absinthe)
  #     conn
  #   end)
  # end
end
