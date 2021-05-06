import Config

config :omega_bravera, OmegaBraveraWeb.Endpoint,
  http: [port: 4000],
  url: [host: System.fetch_env!("HOST_URL"), port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  live_view: [signing_salt: System.fetch_env!("LIVEVIEW_SIGNING_SALT")],
  server: true,
  code_reloader: false

# Do not print debug messages in production
config :logger, level: :debug

config :phoenix, :serve_endpoints, true

config :omega_bravera, Oban,
  repo: OmegaBravera.Repo,
  prune: {:maxlen, 10_000},
  queues: [default: 10, email: 30],
  crontab: [
    # {"0 22 * * 0", OmegaBravera.Accounts.Jobs.WeeklySummary}
    {"0 1 * * *", OmegaBravera.Notifications.Jobs.NotifyDaysNoActivity},
    {"0 0 * * *", OmegaBravera.Notifications.Jobs.NotifyExpiringReward},
    {"* * * * *", OmegaBravera.Offers.Jobs.ExpireOfferRedeem},
    {"0 8 */3 * *", OmegaBravera.Notifications.Jobs.NotifyNewGroupMembers},
    {"0 0 * * *", OmegaBravera.Groups.Jobs.NotifyOrgAdminNewGrpMemberJoined}
  ]

config :sendgrid,
  api_key: System.fetch_env!("SENDGRID_API_KEY")

config :omega_bravera, OmegaBravera.Endpoint,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

# Configure your database
config :omega_bravera, OmegaBravera.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: 20,
  type: OmegaBravera.PostgresTypes

# Strava dev config
config :strava,
  client_id: System.fetch_env!("STRAVA_CLIENT_ID") |> String.to_integer(),
  client_secret: System.fetch_env!("STRAVA_CLIENT_SECRET"),
  access_token: System.fetch_env!("STRAVA_ACCESS_TOKEN"),
  redirect_uri: System.fetch_env!("STRAVA_REDIRECT_URI")

# Stripy dev config
config :omega_bravera, :stripe_public_key, System.fetch_env!("STRIPE_PUBLIC_KEY")

config :stripy,
  secret_key: System.fetch_env!("STRIPE_SECRET_KEY"),
  endpoint: "https://api.stripe.com/v1/"

# Guardian config
config :omega_bravera, OmegaBravera.Guardian,
  issuer: "Bravera.co",
  secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

# S3 Bucket
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: "ap-southeast-1"

config :omega_bravera,
  images_bucket_name: System.fetch_env!("S3_BUCKET"),
  images_cdn_url: System.fetch_env!("CDN_URL")

config :ex_aws, :hackney_opts,
  follow_redirect: true,
  recv_timeout: 30_000

# Mobile App Links Setup
config :omega_bravera,
  app_links_verification: [
    apple: [
      appID: "CULKVWK3RD.co.bravera.braveraMobileApp"
    ],
    google: [
      namespace: "bravera_namespace",
      package_name: "co.bravera.bravera_mobile_app",
      sha256_cert_fingerprints: [
        # Sherief
        "3F:64:3B:A2:A8:E2:5E:CE:61:BC:69:C1:34:A7:5E:2C:EA:3B:FD:98:87:73:8F:A7:83:EB:93:69:91:5F:B7:D1",
        # Allen
        "45:38:9F:CC:BB:DC:D5:1E:9A:80:4E:BF:C2:97:25:57:F8:8B:82:9B:16:9D:86:DF:BC:F9:6B:99:7D:FB:D6:9F",
        # Release
        "DF:6E:65:4C:59:CD:2A:01:83:62:05:7D:CE:40:47:A0:09:EC:5D:32:73:19:37:58:8D:90:75:76:DA:36:D5:86"
      ]
    ]
  ]

# FCM setup
config :pigeon, :fcm,
  fcm_default: %{
    key: System.fetch_env!("FCM_KEY")
  }
