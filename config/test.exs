use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :omega_bravera, OmegaBraveraWeb.Endpoint,
  http: [port: 4001],
  live_view: [
    signing_salt: "921u3oalskdn+asdmaid2123133mm@As"
  ],
  server: false

config :omega_bravera, OmegaBravera.Guardian,
  issuer: "omega_bravera",
  secret_key: "TVCFw5ZzCC5gqI8FeRUg3jT7U578dbb4gGjBXq8Zt1Rk4ctVFj/zTRn6gfGOXiU0"

# Print only warnings and errors during test
config :logger, level: :warn

# Useful when debugging ActivityIngestion tests
# config :logger,
#   backends: [:console],
#   compile_time_purge_level: :debug,
#   level: :debug

# Configure your database
config :omega_bravera, OmegaBravera.Repo,
  username: "postgres",
  password: "postgres",
  database: "omega_bravera_test",
  hostname: System.get_env("DB_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

config :strava,
  client_id: "23267",
  client_secret: "508d46fce35e03a657546bf62283543c9ffe330f",
  access_token: "8830cb6e827146658aa034027d8d399ef1267b46",
  redirect_uri: "http://localhost:4000/strava/callback"

config :sendgrid,
  api_key: "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",
  sandbox_enable: true

config :stripy,
  secret_key: "sk_test_xgwHvfr4GBgJ9wrUDHoa1E57",
  endpoint: "https://api.stripe.com/v1/"

config :bcrypt_elixir, :log_rounds, 1

config :omega_bravera,
  # Manual activities
  enable_manual_activities: false,
  upload_manager: OmegaBravera.UploadManagerMock

config :omega_bravera, Oban, crontab: false, queues: false, prune: :disabled
config :omega_bravera, ObanWeb, stats: false
