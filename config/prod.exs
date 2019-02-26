use Mix.Config

config :omega_bravera, OmegaBraveraWeb.Endpoint,
  http: [port: System.get_env("PORT") || 8080],
  url: [host: System.get_env("APP_HOST"), port: 443, scheme: "https"],
  #  force_ssl: [rewrite_on: [:x_forwarded_proto]], # Disable for Strava
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  code_reloader: false

# Do not print debug messages in production
config :logger, level: :info

config :phoenix, :serve_endpoints, true

config :omega_bravera, OmegaBraveraWeb.Endpoint,
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

config :omega_bravera, OmegaBravera.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 20

config :strava,
  client_id: System.get_env("STRAVA_CLIENT_ID"),
  client_secret: System.get_env("STRAVA_CLIENT_SECRET"),
  access_token: System.get_env("STRAVA_ACCESS_TOKEN"),
  redirect_uri: System.get_env("STRAVA_REDIRECT_URI")

config :stripy,
  secret_key: System.get_env("STRIPE_SECRET_KEY"),
  endpoint: "https://api.stripe.com/v1/"

config :omega_bravera, :stripe_public_key, System.get_env("STRIPE_PUBLIC_KEY")

# Guardian config
config :omega_bravera, OmegaBravera.Guardian,
  issuer: "bravera",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY")

# Email config
config :omega_bravera, OmegaBravera.Mailer,
  adapter: Bamboo.SendgridAdapter,
  api_key: System.get_env("SENDGRID_API_KEY")

config :sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY"),
  sandbox_enable: is_nil(System.get_env("ENABLE_EMAILS"))

# S3 Bucket
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: System.get_env("AWS_REGION")

config :omega_bravera, :images_bucket_name, System.get_env("S3_BUCKET_NAME")

config :ex_aws, :hackney_opts,
  follow_redirect: true,
  recv_timeout: 30_000

# Manual activities
config :omega_bravera,
       :enable_manual_activities,
       not is_nil(System.get_env("ENABLE_MANUAL_ACTIVITIES"))
