use Mix.Config

# Guardian config

config :omega_bravera, OmegaBravera.Guardian,
  issuer: "omega_bravera",
  secret_key: "TVCFw5ZzCC5gqI8FeRUg3jT7U578dbb4gGjBXq8Zt1Rk4ctVFj/zTRn6gfGOXiU0"

# Email config

config :omega_bravera, OmegaBravera.Mailer,
  adapter: Bamboo.SendgridAdapter,
  api_key: "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"

# Strava dev config

config :strava,
  client_id: "23267",
  client_secret: "508d46fce35e03a657546bf62283543c9ffe330f",
  access_token: "8830cb6e827146658aa034027d8d399ef1267b46",
  redirect_uri: "http://localhost:4000/strava/callback"

# Stripy dev config

config :stripy,
  secret_key: "sk_test_xgwHvfr4GBgJ9wrUDHoa1E57",
  endpoint: "https://api.stripe.com/v1/"

config :omega_bravera, :stripe_public_key, "pk_test_RM9ht2ztt3dMgpvjPAtpHOx6"

# Guardian config

config :omega_bravera, OmegaBravera.Guardian,
  issuer: "bravera",
  secret_key: "TVCFw5ZzCC5gqI8FeRUg3jT7U578dbb4gGjBXq8Zt1Rk4ctVFj/zTRn6gfGOXiU0"

# Email config
config :sendgrid,
  api_key: "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",
  sandbox_enable: true

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :omega_bravera, OmegaBraveraWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/brunch/bin/brunch",
      "watch",
      "--stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :omega_bravera, OmegaBraveraWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/omega_bravera_web/views/.*(ex)$},
      ~r{lib/omega_bravera_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :omega_bravera, OmegaBravera.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "omega_bravera_dev",
  hostname: "localhost",
  pool_size: 10

config :omega_bravera, :app_base_url, "http://localhost:4000"

# Manual activities
config :omega_bravera, :enable_manual_activities, not is_nil(System.get_env("ENABLE_MANUAL_ACTIVITIES"))
