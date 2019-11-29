use Mix.Config

config :omega_bravera, OmegaBraveraWeb.Endpoint,
  http: [port: System.get_env("PORT") || 8080],
  url: [host: System.get_env("APP_HOST"), port: 443, scheme: "https"],
  #  force_ssl: [rewrite_on: [:x_forwarded_proto]], # Disable for Strava
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  code_reloader: false

# Do not print debug messages in production
config :logger, level: :error

config :absinthe, Absinthe.Logger,
  filter_variables: ["reset_token", "token", "password_hash", "secret"]

config :absinthe,
  log: true

config :absinthe, Absinthe.Logger,
  pipeline: true

config :phoenix, :serve_endpoints, true

config :omega_bravera, OmegaBraveraWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  live_view: [
    signing_salt: System.get_env("LIVE_SIGNING_SALT")
  ]

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
config :omega_bravera, OmegaBravera.Mail,
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


# Mobile App Links Setup
config :omega_bravera, app_links_verification: [
  apple: [
    appID: "CULKVWK3RD.co.bravera.braveraMobileApp"
  ],
  google: [
    namespace: "bravera_namespace",
    package_name: "co.bravera.bravera_mobile_app",
    sha256_cert_fingerprints: [
      "3F:64:3B:A2:A8:E2:5E:CE:61:BC:69:C1:34:A7:5E:2C:EA:3B:FD:98:87:73:8F:A7:83:EB:93:69:91:5F:B7:D1", # Sherief
      "45:38:9F:CC:BB:DC:D5:1E:9A:80:4E:BF:C2:97:25:57:F8:8B:82:9B:16:9D:86:DF:BC:F9:6B:99:7D:FB:D6:9F", # Allen
      "DF:6E:65:4C:59:CD:2A:01:83:62:05:7D:CE:40:47:A0:09:EC:5D:32:73:19:37:58:8D:90:75:76:DA:36:D5:86" # Release
    ]
  ]
]
