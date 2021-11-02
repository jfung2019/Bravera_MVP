import Config

config :omega_bravera, OmegaBraveraWeb.Endpoint,
  http: [port: 5000],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  code_reloader: false

# Do not print debug messages in production
config :logger, level: :info, backends: [Sentry.LoggerBackend, :console]

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

# Configure your database
config :omega_bravera, OmegaBravera.Repo,
  pool_size: 30,
  type: OmegaBravera.PostgresTypes

config :stripy,
  endpoint: "https://api.stripe.com/v1/"

# Guardian config
config :omega_bravera, OmegaBravera.Guardian, issuer: "Bravera.co"

# S3 Bucket
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: "eu-west-2"

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
